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
const ACTIVATION_CODE_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const VALID_CODE = "CPB-2026-ABC-123";

function captureRpcCalls() {
  const calls: Array<{ url: string; method: string; body?: string }> = [];
  const originalFetch = globalThis.fetch;
  return { calls, originalFetch };
}

function rpcPayload(
  calls: Array<{ url: string; method: string; body?: string }>,
  rpcName: string,
): Record<string, unknown> {
  const call = calls.find((c) => c.url.includes(`/rpc/${rpcName}`));
  assertExists(call, `Expected an RPC call to ${rpcName}`);
  return JSON.parse(call.body ?? "{}");
}

Deno.test(
  "ET3d: POST /payments/redeem with a valid code returns 200 and redeems via RPC for the auth user",
  async () => {
    const { calls, originalFetch } = captureRpcCalls();

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

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: STUDENT_ID,
          email: "student@example.com",
        });
      }

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      if (url.includes("/rest/v1/rpc/check_rate_limit")) {
        return jsonResponse(true);
      }

      if (url.includes("/rest/v1/rpc/redeem_activation_code_for_user")) {
        return jsonResponse([
          {
            activation_code_id: ACTIVATION_CODE_ID,
            product_sku: "premium_lifetime",
            status: "redeemed",
            premium_until: null,
          },
        ]);
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/redeem", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: "Bearer student-session-token",
          },
          body: JSON.stringify({ code: VALID_CODE }),
        }),
      );

      assertEquals(response.status, 200);
      const body = await response.json();
      assertEquals(body.ok, true);
      assertEquals(body.activationCodeId, ACTIVATION_CODE_ID);
      assertEquals(body.productSku, "premium_lifetime");
      assertEquals(body.status, "redeemed");
      assertEquals(body.premium, true);
      assertEquals(body.premium_until, null);

      const redeemPayload = rpcPayload(
        calls,
        "redeem_activation_code_for_user",
      );
      assertEquals(redeemPayload.p_code, VALID_CODE);
      assertEquals(redeemPayload.p_auth_user_id, STUDENT_ID);

      const rateLimitPayload = rpcPayload(calls, "check_rate_limit");
      assertEquals(rateLimitPayload.p_bucket, "redeem_activation_code");
      assertEquals(rateLimitPayload.p_key, STUDENT_ID);
      assertEquals(rateLimitPayload.p_max_attempts, 10);
      assertEquals(rateLimitPayload.p_window_seconds, 60);
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "ET3d: POST /payments/redeem with an unknown code returns 400",
  async () => {
    const { calls, originalFetch } = captureRpcCalls();

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

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: STUDENT_ID,
          email: "student@example.com",
        });
      }

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      if (url.includes("/rest/v1/rpc/check_rate_limit")) {
        return jsonResponse(true);
      }

      if (url.includes("/rest/v1/rpc/redeem_activation_code_for_user")) {
        return jsonResponse(null);
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/redeem", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: "Bearer student-session-token",
          },
          body: JSON.stringify({ code: "UNKNOWN-CODE-999" }),
        }),
      );

      assertEquals(response.status, 400);
      const body = await response.json();
      assertEquals(body.error.message, "Code invalide ou deja utilise");

      const redeemCall = calls.find((call) =>
        call.url.includes("/rpc/redeem_activation_code_for_user")
      );
      assertExists(redeemCall, "RPC must be called for the candidate code");
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "ET3d: POST /payments/redeem returns 400 for revoked, expired, and already-used codes (no premium leak)",
  async () => {
    const statuses = ["revoked", "expired", "already_used", "not_found"];

    for (const status of statuses) {
      const { calls, originalFetch } = captureRpcCalls();

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

        if (url.includes("/auth/v1/user")) {
          return jsonResponse({
            id: STUDENT_ID,
            email: "student@example.com",
          });
        }

        if (url.includes("/rest/v1/app_config")) {
          return jsonResponse(null);
        }

        if (url.includes("/rest/v1/rpc/check_rate_limit")) {
          return jsonResponse(true);
        }

        if (url.includes("/rest/v1/rpc/redeem_activation_code_for_user")) {
          return jsonResponse([
            {
              activation_code_id: status === "not_found"
                ? null
                : ACTIVATION_CODE_ID,
              product_sku: "premium_lifetime",
              status,
              premium_until: null,
            },
          ]);
        }

        throw new Error(`Unexpected fetch call: ${url}`);
      };

      try {
        const response = await handler!(
          new Request("http://localhost/payments/redeem", {
            method: "POST",
            headers: {
              "content-type": "application/json",
              authorization: "Bearer student-session-token",
            },
            body: JSON.stringify({ code: `CPB-2026-${status}` }),
          }),
        );

        assertEquals(response.status, 400, `${status} must not grant premium`);
        const body = await response.json();
        assertEquals(body.error.message, "Code invalide ou deja utilise");
      } finally {
        globalThis.fetch = originalFetch;
      }
    }
  },
);

Deno.test(
  "ET3d: POST /payments/redeem with a malformed JSON body returns 400 (parsed as empty body)",
  async () => {
    const originalFetch = globalThis.fetch;
    const calls: Array<{ url: string; method: string }> = [];

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
      calls.push({ url, method });

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: STUDENT_ID,
          email: "student@example.com",
        });
      }

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/redeem", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: "Bearer student-session-token",
          },
          body: "{not valid json",
        }),
      );

      assertEquals(response.status, 400);
      const body = await response.json();
      assertEquals(body.error.message, "activation code required");

      const redeemCall = calls.find((call) =>
        call.url.includes("/rpc/redeem_activation_code_for_user")
      );
      assertEquals(
        redeemCall,
        undefined,
        "malformed body must not reach the redeem RPC",
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "ET3d: POST /payments/redeem without an activation code returns 400",
  async () => {
    const originalFetch = globalThis.fetch;

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

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/redeem", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: "Bearer student-session-token",
          },
          body: JSON.stringify({ customer_email: "nobody@example.com" }),
        }),
      );

      assertEquals(response.status, 400);
      const body = await response.json();
      assertEquals(body.error.message, "activation code required");
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "ET3d: POST /payments/redeem returns 429 when the redeem rate limit (10/60) is hit",
  async () => {
    const { calls, originalFetch } = captureRpcCalls();

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

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: STUDENT_ID,
          email: "student@example.com",
        });
      }

      if (url.includes("/rest/v1/app_config")) {
        return jsonResponse(null);
      }

      if (url.includes("/rest/v1/rpc/check_rate_limit")) {
        return jsonResponse(false);
      }

      if (url.includes("/rest/v1/rpc/redeem_activation_code_for_user")) {
        throw new Error(
          "redeem_activation_code_for_user must not be called when rate limited",
        );
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request("http://localhost/payments/redeem", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            authorization: "Bearer student-session-token",
          },
          body: JSON.stringify({ code: VALID_CODE }),
        }),
      );

      assertEquals(response.status, 429);
      const body = await response.json();
      assertExists(body.error);

      const rateLimitPayload = rpcPayload(calls, "check_rate_limit");
      assertEquals(rateLimitPayload.p_bucket, "redeem_activation_code");
      assertEquals(rateLimitPayload.p_key, STUDENT_ID);
      assertEquals(rateLimitPayload.p_max_attempts, 10);
      assertEquals(rateLimitPayload.p_window_seconds, 60);
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);