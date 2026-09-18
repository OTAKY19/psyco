import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const envValues = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "service-role-test-key",
  FEDAPAY_WEBHOOK_TOKEN: "webhook-test-token",
  FEDAPAY_WEBHOOK_SECRET: "webhook-test-secret",
  FEDAPAY_SANDBOX_WEBHOOK_SECRET: "sandbox-webhook-test-secret",
  FEDAPAY_SANDBOX_WEBHOOK_TOKEN: "sandbox-webhook-test-token",
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

async function computeFedaPaySignature(
  body: string,
  secret: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

Deno.test("POST /payments_webhook with X-FedaPay-Signature", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";

    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-1",
        status: "pending",
        fulfillment_status: "pending",
      });
    }
    if (url.includes("/rest/v1/payment_provider_events") && method === "POST") {
      return jsonResponse([]);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      return jsonResponse([{
        payment_intent_id: "intent-1",
        product_kind: "license_access",
        fulfillment_status: "fulfilled",
      }]);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const body = JSON.stringify({
      name: "transaction.approved",
      entity: { id: 426549, status: "approved" },
    });
    const signature = await computeFedaPaySignature(
      body,
      "webhook-test-secret",
    );

    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-fedapay-signature": signature,
        },
        body,
      }),
    );

    assertEquals(response.status, 200);
    const result = await response.json();
    assertEquals(result.ok, true);
    assertEquals(result.paymentId, "426549");
    assertEquals(result.processed, true);
    assertEquals(result.status, "completed");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook rejects invalid HMAC signature", async () => {
  const body = JSON.stringify({ id: 426549, status: "approved" });

  const response = await handler!(
    new Request("http://localhost/payments_webhook", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-fedapay-signature": "aW52YWxpZC1zaWduYXR1cmU=",
      },
      body,
    }),
  );

  assertEquals(response.status, 401);
  const result = await response.json();
  assertEquals(result.error.message, "Unauthorized webhook");
});

Deno.test("POST /payments_webhook with sandbox X-FedaPay-Signature", async () => {
  const originalFetch = globalThis.fetch;
  const previousMode = Deno.env.get("FEDAPAY_MODE");
  Deno.env.set("FEDAPAY_MODE", "sandbox");

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";

    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-sandbox",
        status: "pending",
        fulfillment_status: "pending",
      });
    }
    if (url.includes("/rest/v1/payment_provider_events") && method === "POST") {
      return jsonResponse([]);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      return jsonResponse([{
        payment_intent_id: "intent-sandbox",
        product_kind: "license_access",
        fulfillment_status: "fulfilled",
      }]);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const body = JSON.stringify({
      name: "transaction.approved",
      entity: { id: 98765, status: "approved" },
    });
    const signature = await computeFedaPaySignature(
      body,
      "sandbox-webhook-test-secret",
    );

    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-fedapay-signature": signature,
        },
        body,
      }),
    );

    assertEquals(response.status, 200);
    const result = await response.json();
    assertEquals(result.ok, true);
    assertEquals(result.paymentId, "98765");
    assertEquals(result.processed, true);
    assertEquals(result.status, "completed");
  } finally {
    globalThis.fetch = originalFetch;
    if (previousMode !== undefined) {
      Deno.env.set("FEDAPAY_MODE", previousMode);
    } else {
      Deno.env.delete("FEDAPAY_MODE");
    }
  }
});

Deno.test("POST /payments_webhook with X-Webhook-Token still works", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";

    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-2",
        status: "pending",
        fulfillment_status: "pending",
      });
    }
    if (url.includes("/rest/v1/payment_provider_events") && method === "POST") {
      return jsonResponse([]);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      return jsonResponse([{
        payment_intent_id: "intent-2",
        product_kind: "license_access",
        fulfillment_status: "fulfilled",
      }]);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "webhook-test-token",
        },
        body: JSON.stringify({
          name: "transaction.approved",
          entity: { id: 426549, status: "approved" },
        }),
      }),
    );

    assertEquals(response.status, 200);
    const result = await response.json();
    assertEquals(result.ok, true);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook accepts valid token in query string (deprecated)", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";

    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-426549",
        status: "pending",
        fulfillment_status: "pending",
      });
    }
    if (url.includes("/rest/v1/payment_provider_events") && method === "POST") {
      return jsonResponse([]);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      return jsonResponse([{
        payment_intent_id: "intent-426549",
        product_kind: "license_access",
        fulfillment_status: "fulfilled",
      }]);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook?token=webhook-test-token", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ id: 426549, status: "approved" }),
      }),
    );

    assertEquals(response.status, 200);
    const result = await response.json();
    assertEquals(result.ok, true);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook rejects invalid token in query string", async () => {
  const response = await handler!(
    new Request("http://localhost/payments_webhook?token=bad-token", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ id: 426549, status: "approved" }),
    }),
  );

  assertEquals(response.status, 401);
  const result = await response.json();
  assertEquals(result.error.message, "Unauthorized webhook");
});

Deno.test("POST /payments_webhook skips fulfill on amount mismatch", async () => {
  const originalFetch = globalThis.fetch;
  let rpcCalled = false;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);

    if (url.includes("/rest/v1/payment_intents") && init?.method === "GET") {
      return jsonResponse({
        id: "intent-amount-mismatch",
        status: "pending",
        fulfillment_status: "pending",
        amount_xof: 50000,
      });
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      rpcCalled = true;
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      rpcCalled = true;
      return jsonResponse([]);
    }
    if (url.includes("/rest/v1/payment_provider_events")) {
      rpcCalled = true;
      return jsonResponse([]);
    }
    throw new Error(`Unexpected fetch: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "webhook-test-token",
        },
        body: JSON.stringify({
          name: "transaction.approved",
          entity: { id: "txn-amount-mismatch", status: "approved", amount: 100 },
        }),
      }),
    );

    assertEquals(response.status, 422);
    const result = await response.json();
    assertStringIncludes(result.error.message, "Amount mismatch");
    assertEquals(rpcCalled, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook skips fulfill when RPC returns false (race condition)", async () => {
  const originalFetch = globalThis.fetch;
  let fulfillCalled = false;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request ? input.method : init?.method ?? "GET";

    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-race",
        status: "completed",
        fulfillment_status: "fulfilled",
        amount_xof: 10000,
      });
    }
    if (url.includes("/rest/v1/payment_provider_events") && method === "POST") {
      return jsonResponse([]);
    }
    if (url.includes("/rpc/update_payment_intent_status_if")) {
      return jsonResponse(false);
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    if (url.includes("/rpc/fulfill_payment_intent")) {
      fulfillCalled = true;
      return jsonResponse([]);
    }
    throw new Error(`Unexpected fetch: ${url}`);
  };

  try {
    await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "webhook-test-token",
        },
        body: JSON.stringify({
          name: "transaction.approved",
          entity: { id: "txn-race", status: "approved" },
        }),
      }),
    );

    assertEquals(fulfillCalled, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook rejects empty JSON body", async () => {
  const response = await handler!(
    new Request("http://localhost/payments_webhook", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-webhook-token": "webhook-test-token",
      },
      body: "",
    }),
  );
  assertEquals(response.status, 400);
  const result = await response.json();
  assertEquals(result.ok, false);
});

Deno.test("POST /payments_webhook rejects malformed JSON body", async () => {
  const response = await handler!(
    new Request("http://localhost/payments_webhook", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-webhook-token": "webhook-test-token",
      },
      body: "not valid json at all",
    }),
  );
  assertEquals(response.status, 400);
  const result = await response.json();
  assertEquals(result.ok, false);
  assertEquals(result.processed, false);
});

Deno.test("POST /payments_webhook returns 422 when transactionId is missing", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    if (url.includes("/rpc/check_rate_limit")) {
      return new Response(JSON.stringify(true), { status: 200, headers: { "content-type": "application/json" } });
    }
    throw new Error(`Unexpected fetch: ${url}`);
  };
  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "webhook-test-token",
        },
        body: JSON.stringify({ name: "transaction.approved", entity: {} }),
      }),
    );
    assertEquals(response.status, 422);
    const result = await response.json();
    assertEquals(result.ok, false);
    assertEquals(result.processed, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments_webhook rejects sandbox webhook for live payment_intent", async () => {
  const originalFetch = globalThis.fetch;
  const previousMode = Deno.env.get("FEDAPAY_MODE");
  Deno.env.set("FEDAPAY_MODE", "sandbox");

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : String(input);
    const method = input instanceof Request ? input.method : init?.method ?? "GET";

    if (url.includes("/rest/v1/payment_intents") && method === "GET") {
      return jsonResponse({
        id: "intent-cross-env",
        status: "pending",
        fulfillment_status: "pending",
        environment: "live",
      });
    }
    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "sandbox-webhook-test-token",
        },
        body: JSON.stringify({
          name: "transaction.approved",
          entity: { id: "cross-env-txn", status: "approved" },
        }),
      }),
    );

    assertEquals(response.status, 403);
    const result = await response.json();
    assertEquals(result.error.message, "Webhook environment mismatch: webhook=sandbox, intent=live");
  } finally {
    globalThis.fetch = originalFetch;
    if (previousMode !== undefined) {
      Deno.env.set("FEDAPAY_MODE", previousMode);
    } else {
      Deno.env.delete("FEDAPAY_MODE");
    }
  }
});

Deno.test("POST /payments_webhook rejects when webhook environment != current mode", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request ? input.url : String(input);

    if (url.includes("/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments_webhook", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-webhook-token": "sandbox-webhook-test-token",
        },
        body: JSON.stringify({
          name: "transaction.approved",
          entity: { id: "mode-mismatch-txn", status: "approved" },
        }),
      }),
    );

    assertEquals(response.status, 403);
    const result = await response.json();
    assertEquals(result.ok, false);
    assertEquals(result.processed, false);
    assertEquals(result.error, "Webhook environment mismatch: webhook=sandbox, current=live");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
