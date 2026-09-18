import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const envValues = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-test-key",
  SUPABASE_SERVICE_ROLE_KEY: "service-role-test-key",
  CLE_SECRETE: "fedapay-test-token",
  PAYMENT_APP_TOKEN: "payment-app-test-token",
  FEDAPAY_CALLBACK_URL:
    "https://example.supabase.co/functions/v1/payments_webhook",
};

for (const [key, value] of Object.entries(envValues)) {
  Deno.env.set(key, value);
}

let handler: ((req: Request) => Promise<Response>) | null = null;

Object.defineProperty(Deno, "serve", {
  value: (serveHandler: (req: Request) => Promise<Response>) => {
    handler = serveHandler;
    return { close() {} };
  },
  configurable: true,
});

await import("./index.ts");

if (!handler) {
  throw new Error("Handler not captured");
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

const STUDENT_ID = "11111111-1111-4111-8111-111111111111";
const COMPLETED_INTENT_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";

const completedIntent = {
  id: COMPLETED_INTENT_ID,
  auth_user_id: STUDENT_ID,
  provider_payment_ref: "429001",
  status: "completed",
  fulfillment_status: "fulfilled",
};

async function runVerifyWithGrant(
  grant: Record<string, unknown>,
): Promise<Response> {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async (input: RequestInfo | URL) => {
      const url = input instanceof Request
        ? input.url
        : input instanceof URL
        ? input.toString()
        : String(input);

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: STUDENT_ID,
          email: "student@example.com",
        });
      }

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      if (url.includes("/rest/v1/payment_intents")) {
        return jsonResponse(completedIntent);
      }

      if (url.includes("/rest/v1/user_access_grants")) {
        return jsonResponse(grant);
      }

      if (url.includes("/rest/v1/rpc/fulfill_payment_intent")) {
        throw new Error(
          "fulfill_payment_intent must be skipped for a fulfilled intent",
        );
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    return await handler!(
      new Request(
        `http://localhost/payments/${COMPLETED_INTENT_ID}/verify`,
        {
          method: "GET",
          headers: {
            authorization: "Bearer student-session-token",
          },
        },
      ),
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
}

Deno.test(
  "ET1f: verify returns premium:true when stored grant has NULL ends_at (lifetime)",
  async () => {
    const response = await runVerifyWithGrant({
      ends_at: null,
      status: "active",
    });

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.status, "completed");
    assertEquals(body.premium, true);
    assertEquals(body.premium_until, null);
    assertEquals(body.fulfillment_status, "fulfilled");
  },
);

Deno.test(
  "ET1f: verify returns premium:true when stored grant omits ends_at (lifetime)",
  async () => {
    const response = await runVerifyWithGrant({ status: "active" });

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.premium, true);
    assertEquals(body.premium_until, null);
  },
);

Deno.test(
  "ET1f: verify returns premium:false when stored grant already expired",
  async () => {
    const past = new Date(Date.now() - 5 * 86400000).toISOString();
    const response = await runVerifyWithGrant({
      ends_at: past,
      status: "active",
    });

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.premium, false);
    assertEquals(body.premium_until, past);
  },
);

Deno.test(
  "ET1f: verify returns premium:true when stored grant is still in the future",
  async () => {
    const future = new Date(Date.now() + 400 * 86400000).toISOString();
    const response = await runVerifyWithGrant({
      ends_at: future,
      status: "active",
    });

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.premium, true);
    assertEquals(body.premium_until, future);
  },
);

Deno.test(
  "ET1f: anonymous fulfillment lands a lifetime premium activation",
  async () => {
    const originalFetch = globalThis.fetch;
    const calls: Array<{ url: string; method: string; body?: string }> = [];

    globalThis.fetch = async (
      input: RequestInfo | URL,
      init?: RequestInit,
    ) => {
      const url = input instanceof Request
        ? input.url
        : input instanceof URL
        ? input.toString()
        : String(input);
      const method = input instanceof Request
        ? input.method
        : init?.method ?? "GET";
      let body: string | undefined;
      if (input instanceof Request) {
        try {
          body = await input.clone().text();
        } catch {
          body = undefined;
        }
      } else {
        body = init?.body?.toString();
      }
      calls.push({ url, method, body });

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      if (
        url.includes("/rest/v1/payment_intents") &&
        url.includes("provider_payment_ref")
      ) {
        return jsonResponse(null);
      }

      if (url.includes("/rest/v1/catalog_products")) {
        return jsonResponse({
          id: "22222222-2222-4222-8222-222222222222",
          sku: "premium_lifetime",
          kind: "license_access",
          name: "Acces a vie PsycoTest+",
          amount_xof: 3000,
          currency: "XOF",
          premium_duration_days: null,
          is_active: true,
        });
      }

      if (url.endsWith("/transactions/999913")) {
        return jsonResponse({
          status: "approved",
          custom_metadata: {
            device_id: "device-lifetime-001",
            app: "PsycoTest+",
          },
        });
      }

      if (url.includes("/rest/v1/rpc/apply_paid_payment")) {
        return jsonResponse({
          processed_once: true,
          premium_until: null,
          device_token: "tok-device-lifetime",
        });
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/999913/verify", {
          method: "GET",
          headers: {
            "x-app-token": envValues.PAYMENT_APP_TOKEN,
          },
        }),
      );

      assertEquals(response.status, 200);
      const body = await response.json();
      assertEquals(body.status, "completed");
      assertEquals(body.premium, true);
      assertExists(body.premium_until);

      const lifetimeHorizon = Date.now() + 36400 * 86400000;
      assertEquals(
        new Date(body.premium_until).getTime() > lifetimeHorizon,
        true,
        "lifetime grant must extend ~100 years, not a fixed 90-day window",
      );

      const rpcCall = calls.find((call) =>
        call.url.includes("/rest/v1/rpc/apply_paid_payment")
      );
      assertExists(rpcCall, "apply_paid_payment RPC must be called");
      const payload = JSON.parse(rpcCall.body ?? "{}");
      assertEquals(payload.p_payment_id, "999913");
      assertEquals(payload.p_device_id, "device-lifetime-001");
      assertEquals(payload.p_amount, 3000);

      const paidUntil = new Date(payload.p_premium_until ?? "");
      assertEquals(Number.isNaN(paidUntil.getTime()), false);
      assertEquals(
        paidUntil.getTime() > lifetimeHorizon,
        true,
        "NULL catalog duration must be coalesced to a lifetime horizon",
      );
      assertEquals(body.device_token, "tok-device-lifetime");
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);