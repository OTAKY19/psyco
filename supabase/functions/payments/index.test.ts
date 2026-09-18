import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const envValues = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-test-key",
  SUPABASE_SERVICE_ROLE_KEY: "service-role-test-key",
  JWT_SECRET: "jwt-test-secret",
  CLE_SECRETE: "fedapay-test-token",
  PAYMENT_APP_TOKEN: "payment-app-test-token",
  FEDAPAY_WEBHOOK_TOKEN: "webhook-test-token",
  FEDAPAY_CALLBACK_URL:
    "https://example.supabase.co/functions/v1/payments/webhook",
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

Deno.test("POST /payments falls back to checkout when no-redirect fails", async () => {
  const calls: Array<{ url: string; method: string }> = [];
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    calls.push({ url, method });

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "POST") {
      return jsonResponse({
        id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        auth_user_id: null,
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "PATCH") {
      return jsonResponse([]);
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 426495,
          reference: "trx_test_001",
          status: "pending",
          payment_url: "https://sandbox-process.fedapay.com/test",
          payment_token: "token_test_001",
        },
      });
    }

    if (url.endsWith("/transactions/mtn")) {
      return jsonResponse(
        { message: "Operation not allowed" },
        400,
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-app-token": envValues.PAYMENT_APP_TOKEN,
        },
        body: JSON.stringify({
          device_id: "device-real-sandbox-001",
          currency: "XOF",
          description: "Test sandbox FedaPay",
          provider: "MTN_MOMO_BEN",
          customer: {
            email: "test@example.com",
            firstName: "Test",
            lastName: "Sandbox",
            phone: "+22990000000",
          },
        }),
      }),
    );

    assertEquals(response.status, 200);

    const body = await response.json();
    assertEquals(body.gateway, "fedapay");
    assertEquals(body.status, "pending");
    assertExists(body.checkoutUrl);
    assertEquals(body.flow, undefined);
    assertEquals(body.noRedirect, undefined);
    const txCall = calls.find((call) =>
      call.url.endsWith("/transactions") &&
      !call.url.endsWith("/transactions/mtn")
    );
    assertExists(txCall);
    const mtnCall = calls.find((call) =>
      call.url.endsWith("/transactions/mtn")
    );
    assertExists(mtnCall);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments does not accept bearer token as app token", async () => {
  const response = await handler!(
    new Request("http://localhost/payments", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${envValues.PAYMENT_APP_TOKEN}`,
      },
      body: JSON.stringify({
        device_id: "device-real-sandbox-001",
        currency: "XOF",
        description: "Test sandbox FedaPay",
        provider: "MTN_MOMO_BEN",
        customer: {
          email: "test@example.com",
          firstName: "Test",
          lastName: "Sandbox",
          phone: "+22990000000",
        },
      }),
    }),
  );

  assertEquals(response.status, 401);
  const body = await response.json();
  assertEquals(body.error.message, "Unauthorized");
});

Deno.test("POST /payments creates a JWT-backed payment intent", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string; body?: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
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
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      const payload = JSON.parse(body ?? "{}");
      assertEquals(payload.p_bucket, "create_payment");
      assertEquals(payload.p_key, "11111111-1111-4111-8111-111111111111");
      assertEquals(payload.p_max_attempts, 5);
      assertEquals(payload.p_window_seconds, 60);
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "POST") {
      return jsonResponse({
        id: "33333333-3333-4333-8333-333333333333",
        auth_user_id: "11111111-1111-4111-8111-111111111111",
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 426777,
          reference: "trx_secure_001",
          status: "pending",
          payment_url: "https://sandbox-process.fedapay.com/secure",
          payment_token: "token_secure_001",
        },
      });
    }

    if (url.endsWith("/transactions/mtn")) {
      return jsonResponse(
        { message: "Operation not allowed" },
        400,
      );
    }

    if (url.includes("/rest/v1/payment_intents") && method === "PATCH") {
      return jsonResponse([]);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          currency: "XOF",
          description: "Test secure FedaPay",
          provider: "MTN",
          customer: {
            email: "student@example.com",
            firstName: "Awa",
            lastName: "Sow",
            phone: "+22990000000",
          },
        }),
      }),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.paymentId, "33333333-3333-4333-8333-333333333333");
    assertEquals(body.providerPaymentId, "426777");
    assertEquals(body.amount, 3000);
    assertEquals(body.premiumDurationDays, null);
    assertExists(body.checkoutUrl);

    const insertCall = calls.find((call) =>
      call.url.includes("/rest/v1/payment_intents") &&
      call.method === "POST"
    );
    assertExists(insertCall);
    const insertPayload = JSON.parse(insertCall.body ?? "{}");
    assertEquals(
      insertPayload.auth_user_id,
      "11111111-1111-4111-8111-111111111111",
    );
    assertEquals(
      insertPayload.product_id,
      "22222222-2222-4222-8222-222222222222",
    );
    assertEquals(insertPayload.provider, "mtn");
    assertEquals(insertPayload.phone_e164, "+22990000000");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments JWT-backed includes device_id in FedaPay metadata", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string; body?: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
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
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "POST") {
      return jsonResponse({
        id: "33333333-3333-4333-8333-333333333333",
        auth_user_id: "11111111-1111-4111-8111-111111111111",
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "PATCH") {
      return jsonResponse([]);
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 426888,
          reference: "trx_deviceid_001",
          status: "pending",
          payment_url: "https://checkout.fedapay.com/test",
          payment_token: "token_deviceid_001",
        },
      });
    }

    if (url.endsWith("/transactions/mtn")) {
      return jsonResponse(
        { message: "Operation not allowed" },
        400,
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          device_id: "test-device-abc-123",
          currency: "XOF",
          provider: "MTN",
          customer: {
            email: "student@example.com",
            firstName: "Awa",
            lastName: "Sow",
            phone: "+22990000000",
          },
        }),
      }),
    );

    assertEquals(response.status, 200);

    const fedaPayCall = calls.find((call) =>
      call.url.endsWith("/transactions") && call.method === "POST"
    );
    assertExists(fedaPayCall);
    const requestBody = JSON.parse(fedaPayCall.body ?? "{}");
    const customMetadata = requestBody.custom_metadata ?? {};
    assertEquals(
      customMetadata.device_id,
      "test-device-abc-123",
      "device_id must be included in FedaPay custom_metadata",
    );
    assertEquals(
      customMetadata.payment_intent_id,
      "33333333-3333-4333-8333-333333333333",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments creates partner pack payment for active activation pack SKU", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string; body?: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
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
        id: "11111111-1111-4111-8111-111111111111",
        email: "partner@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/current_partner_id_for_auth_user")) {
      return jsonResponse("44444444-4444-4444-8444-444444444444");
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      const payload = JSON.parse(body ?? "{}");
      assertEquals(payload.p_bucket, "create_payment");
      assertEquals(payload.p_key, "11111111-1111-4111-8111-111111111111");
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/partners")) {
      return jsonResponse({
        id: "44444444-4444-4444-8444-444444444444",
        code: "PARTNER001",
      });
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "55555555-5555-4555-8555-555555555555",
        sku: "partner_pack_20",
        kind: "activation_pack",
        name: "Pack 20",
        amount_xof: 45000,
        currency: "XOF",
        premium_duration_days: null,
        activation_code_quantity: 20,
        package_name: "Pack 20",
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse(null);
    }

    if (url.includes("/rest/v1/payment_intents") && method === "POST") {
      return jsonResponse({
        id: "66666666-6666-4666-8666-666666666666",
        auth_user_id: "11111111-1111-4111-8111-111111111111",
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "PATCH") {
      return jsonResponse([]);
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 426999,
          reference: "trx_partner_001",
          status: "pending",
          payment_url: "https://checkout.fedapay.com/partner",
          payment_token: "token_partner_001",
        },
      });
    }

    if (url.endsWith("/transactions/mtn")) {
      return jsonResponse(
        { message: "Operation not allowed" },
        400,
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer partner-session-token",
        },
        body: JSON.stringify({
          product_sku: "partner_pack_20",
          partner_code: "PARTNER001",
          currency: "XOF",
          provider: "MTN",
          metadata: {
            origin: "partner_screen",
          },
        }),
      }),
    );

    assertEquals(response.status, 200);
    const responseBody = await response.json();
    assertEquals(responseBody.gateway, "fedapay");
    assertEquals(responseBody.amount, 45000);
    assertEquals(responseBody.partnerCode, "PARTNER001");

    const insertCall = calls.find((call) =>
      call.url.includes("/rest/v1/payment_intents") &&
      call.method === "POST"
    );
    assertExists(insertCall);
    const insertPayload = JSON.parse(insertCall.body ?? "{}");
    assertEquals(
      insertPayload.auth_user_id,
      "11111111-1111-4111-8111-111111111111",
    );
    assertEquals(
      insertPayload.partner_id,
      "44444444-4444-4444-8444-444444444444",
    );
    assertEquals(
      insertPayload.product_id,
      "55555555-5555-4555-8555-555555555555",
    );
    assertEquals(insertPayload.amount_xof, 45000);
    assertEquals(insertPayload.raw_metadata.partner_pack, true);
    assertEquals(insertPayload.raw_metadata.quantity, 20);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments rejects partner payment for non-activation products", async () => {
  const originalFetch = globalThis.fetch;
  let catalogLookupCalled = false;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "partner@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/current_partner_id_for_auth_user")) {
      return jsonResponse("44444444-4444-4444-8444-444444444444");
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/partners")) {
      return jsonResponse({
        id: "44444444-4444-4444-8444-444444444444",
        code: "PARTNER001",
      });
    }

    if (url.includes("/rest/v1/catalog_products")) {
      catalogLookupCalled = true;
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        activation_code_quantity: null,
        package_name: null,
        is_active: true,
      });
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer partner-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          partner_code: "PARTNER001",
          provider: "MTN",
          phone: "+22990000000",
        }),
      }),
    );

    assertEquals(response.status, 422);
    const body = await response.json();
    assertEquals(
      body.error.message,
      "Partner payments require activation_pack products",
    );
    assertEquals(catalogLookupCalled, true);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments rejects partner codes for authenticated users without partner account", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/current_partner_id_for_auth_user")) {
      return jsonResponse(null);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          partner_code: "ABC123",
          provider: "MTN",
          customer: {
            phone: "+22990000000",
          },
        }),
      }),
    );

    assertEquals(response.status, 403);
    const body = await response.json();
    assertEquals(
      body.error.message,
      "Compte partenaire requis. Lie d'abord ton profil partenaire a ton compte.",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments rejects partner metadata for authenticated users without partner account", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/current_partner_id_for_auth_user")) {
      return jsonResponse(null);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          provider: "MTN",
          customer: {
            phone: "+22990000000",
          },
          metadata: {
            partner_code: "ABC123",
          },
        }),
      }),
    );

    assertEquals(response.status, 403);
    const body = await response.json();
    assertEquals(
      body.error.message,
      "Compte partenaire requis. Lie d'abord ton profil partenaire a ton compte.",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments allows anonymous JWT-backed student payments", async () => {
  const originalFetch = globalThis.fetch;

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

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        is_anonymous: true,
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
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

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse([]);
    }

    if (url.includes("/rest/v1/payment_intents") && method === "POST") {
      return jsonResponse({
        id: "33333333-3333-4333-8333-333333333333",
        auth_user_id: "11111111-1111-4111-8111-111111111111",
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.includes("/rest/v1/payment_intents") && method === "PATCH") {
      return jsonResponse([]);
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 426999,
          reference: "trx_anon_001",
          status: "pending",
          payment_url: "https://sandbox-process.fedapay.com/test",
          payment_token: "token_anon_001",
        },
      });
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer anonymous-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          provider: "MTN",
          customer: {
            phone: "+22990000000",
          },
        }),
      }),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.status, "pending");
    assertEquals(body.paymentId, "33333333-3333-4333-8333-333333333333");
    assertEquals(body.providerPaymentId, "426999");
    assertExists(body.checkoutUrl);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("GET /payments/{id}/verify returns pending when FedaPay is pending", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.endsWith("/transactions/426495")) {
      return jsonResponse({ status: "pending" });
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments/426495/verify", {
        method: "GET",
        headers: {
          "x-app-token": envValues.PAYMENT_APP_TOKEN,
        },
      }),
    );

    assertEquals(response.status, 200);

    const body = await response.json();
    assertEquals(body.status, "pending");
    assertEquals(body.premium, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("GET /payments/{id}/verify falls back to DB for device_id when metadata missing", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";
    calls.push({ url, method });

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "prod-premium-90d",
        sku: "premium_lifetime",
        kind: "premium",
        name: "Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
        activation_code_quantity: null,
        package_name: null,
      });
    }

    if (url.endsWith("/transactions/426999")) {
      return jsonResponse({
        status: "approved",
        v1_transaction: {
          id: 426999,
          reference: "trx_fallback_001",
          status: "approved",
        },
        custom_metadata: {
          payment_intent_id: "44444444-4444-4444-8444-444444444444",
          app: "Code Permis Benin",
        },
      });
    }

    // DB lookup for payment_intent by id returns a row with device_id
    if (
      url.includes("/rest/v1/payment_intents") &&
      url.includes("44444444-4444-4444-8444-444444444444")
    ) {
      return jsonResponse({
        id: "44444444-4444-4444-8444-444444444444",
        device_id: "device-from-db-987",
      });
    }

    // applyPaidPayment RPC
    if (url.includes("/rest/v1/rpc/apply_paid_payment")) {
      return jsonResponse({
        processed_once: false,
        premium_until: new Date(Date.now() + 90 * 86400000).toISOString(),
      });
    }

    // fulfillPaymentIntent RPC
    if (url.includes("/rest/v1/rpc/fulfill_payment_intent")) {
      return jsonResponse([]);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments/426999/verify", {
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

    const dbLookup = calls.find((call) =>
      call.url.includes("/rest/v1/payment_intents") &&
      call.url.includes("44444444-4444-4444-8444-444444444444")
    );
    assertExists(
      dbLookup,
      "Should have looked up payment_intent by ID from metadata",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("GET /payments/{uuid}/verify resolves UUID to FedaPay transaction ID", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";
    calls.push({ url, method });

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    // DB lookup: payment_intents by UUID returns provider_payment_ref
    if (
      url.includes("/rest/v1/payment_intents") &&
      url.includes("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
    ) {
      return jsonResponse({
        id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        provider_payment_ref: "428001",
        status: "approved",
        fulfillment_status: "pending",
      });
    }

    // FedaPay API lookup with the resolved numeric transaction ID
    if (url.endsWith("/transactions/428001")) {
      return jsonResponse({
        id: 428001,
        reference: "trx_uuid_resolve_001",
        status: "approved",
        custom_metadata: {
          payment_intent_id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
          device_id: "device-from-uuid-555",
          app: "Code Permis Benin",
          product: "premium_access",
        },
      });
    }

    // Catalog product lookup
    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "prod-premium-90d",
        sku: "premium_lifetime",
        kind: "premium",
        name: "Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
        activation_code_quantity: null,
        package_name: null,
      });
    }

    // applyPaidPayment RPC
    if (url.includes("/rest/v1/rpc/apply_paid_payment")) {
      return jsonResponse({
        processed_once: true,
        premium_until: new Date(Date.now() + 90 * 86400000).toISOString(),
      });
    }

    // fulfillPaymentIntent RPC
    if (url.includes("/rest/v1/rpc/fulfill_payment_intent")) {
      return jsonResponse([]);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request(
        "http://localhost/payments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/verify",
        {
          method: "GET",
          headers: {
            "x-app-token": envValues.PAYMENT_APP_TOKEN,
          },
        },
      ),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.status, "completed");
    assertEquals(body.premium, true);

    // Verify the DB lookup happened before the FedaPay call
    const dbLookup = calls.find((call) =>
      call.url.includes("/rest/v1/payment_intents") &&
      call.url.includes("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
    );
    assertExists(dbLookup, "Should have looked up payment_intent by UUID");

    const fedapayCall = calls.find((call) =>
      call.url.endsWith("/transactions/428001")
    );
    assertExists(
      fedapayCall,
      "Should have called FedaPay with resolved numeric transaction ID",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("GET /payments/{id}/verify returns completed from DB without FedaPay call", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";
    calls.push({ url, method });

    // DB lookup by provider_payment_ref returns completed
    if (
      url.includes("/rest/v1/payment_intents") &&
      url.includes("provider_payment_ref") &&
      url.includes("999001")
    ) {
      return jsonResponse({
        id: "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        provider_payment_ref: "999001",
        status: "completed",
        fulfillment_status: "fulfilled",
      });
    }

    // If FedaPay is called, fail the test
    if (url.endsWith("/transactions/999001")) {
      throw new Error("Should NOT call FedaPay when DB says completed");
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments/999001/verify", {
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
    assertEquals(body.fulfillment_status, "fulfilled");

    const fedapayCall = calls.find((call) =>
      call.url.endsWith("/transactions/999001")
    );
    assertEquals(
      fedapayCall,
      undefined,
      "Should NOT have called FedaPay; DB short-circuited",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("GET /payments/{uuid}/verify skips FedaPay when DB status is completed", async () => {
  const originalFetch = globalThis.fetch;
  const calls: Array<{ url: string; method: string }> = [];

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    const method = input instanceof Request
      ? input.method
      : init?.method ?? "GET";
    calls.push({ url, method });

    // DB lookup by UUID returns completed status
    if (
      url.includes("/rest/v1/payment_intents") &&
      url.includes("dddddddd-dddd-4ddd-8ddd-dddddddddddd")
    ) {
      return jsonResponse({
        id: "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
        provider_payment_ref: "999002",
        status: "completed",
        fulfillment_status: "fulfilled",
      });
    }

    // If FedaPay is called, fail the test
    if (url.endsWith("/transactions/999002")) {
      throw new Error("Should NOT call FedaPay when DB says completed");
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request(
        "http://localhost/payments/dddddddd-dddd-4ddd-8ddd-dddddddddddd/verify",
        {
          method: "GET",
          headers: {
            "x-app-token": envValues.PAYMENT_APP_TOKEN,
          },
        },
      ),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.status, "completed");
    assertEquals(body.premium, true);
    assertEquals(body.fulfillment_status, "fulfilled");

    const dbLookup = calls.find((call) =>
      call.url.includes("/rest/v1/payment_intents") &&
      call.url.includes("dddddddd-dddd-4ddd-8ddd-dddddddddddd")
    );
    assertExists(dbLookup, "Should have looked up payment_intent by UUID");

    const fedapayCall = calls.find((call) =>
      call.url.endsWith("/transactions/999002")
    );
    assertEquals(
      fedapayCall,
      undefined,
      "Should NOT have called FedaPay; DB short-circuited",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments logs warn when body.amount differs from effectiveAmount", async () => {
  const originalFetch = globalThis.fetch;
  const originalWarn = console.warn;
  const warnCalls: string[] = [];

  console.warn = (...args: unknown[]) => {
    warnCalls.push(args.map(String).join(" "));
  };

  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "33333333-3333-4333-8333-333333333333",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse(null);
    }

    if (url.includes("/rest/v1/payment_intents") && init?.method === "POST") {
      return jsonResponse({
        id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
        auth_user_id: null,
        provider_payment_ref: null,
        status: "created",
        fulfillment_status: "pending",
      });
    }

    if (url.includes("/rest/v1/payment_intents") && init?.method === "PATCH") {
      return jsonResponse([]);
    }

    if (url.endsWith("/transactions")) {
      return jsonResponse({
        "v1/transaction": {
          id: 999003,
          reference: "trx_mismatch_001",
          status: "pending",
          payment_url: "https://sandbox-process.fedapay.com/test",
          payment_token: "token_mismatch_001",
        },
      });
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          amount: 100,
          customer: { phone: "+22999999999" },
          country: "BEN",
          provider: "MTN",
          metadata: { origin: "student_screen" },
        }),
      }),
    );

    assertEquals(response.status, 200);
    const hasWarn = warnCalls.some((w) => w.includes("[price-mismatch]"));
    assertEquals(hasWarn, true);
  } finally {
    globalThis.fetch = originalFetch;
    console.warn = originalWarn;
  }
});

// POST /payments/webhook tests removed: webhook moved to
// payments_webhook/index.ts (see payments_webhook/index.test.ts)

Deno.test(
  "GET /payments/{uuid}/verify with bearer token returns completed from DB",
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
          id: "11111111-1111-4111-8111-111111111111",
          email: "student@example.com",
        });
      }

      if (
        url.includes("/rest/v1/payment_intents") &&
        url.includes("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
      ) {
        return jsonResponse({
          id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
          auth_user_id: "11111111-1111-4111-8111-111111111111",
          provider_payment_ref: "428001",
          status: "completed",
          fulfillment_status: "pending",
        });
      }

      if (url.includes("/rest/v1/rpc/fulfill_payment_intent")) {
        return jsonResponse({
          processed_once: false,
          premium_until: new Date(Date.now() + 90 * 86400000).toISOString(),
        });
      }

      if (url.includes("/rest/v1/user_access_grants")) {
        return jsonResponse({
          ends_at: new Date(Date.now() + 90 * 86400000).toISOString(),
          status: "active",
        });
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request(
          "http://localhost/payments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/verify",
          {
            method: "GET",
            headers: {
              authorization: "Bearer student-session-token",
            },
          },
        ),
      );

      assertEquals(response.status, 200);
      const body = await response.json();
      assertEquals(body.status, "completed");
      assertEquals(body.premium, true);
      assertExists(body.premium_until);
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "GET /payments/{uuid}/verify with bearer token returns pending when FedaPay is pending",
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
          id: "11111111-1111-4111-8111-111111111111",
          email: "student@example.com",
        });
      }

      if (
        url.includes("/rest/v1/payment_intents") &&
        url.includes("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")
      ) {
        return jsonResponse({
          id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
          auth_user_id: "11111111-1111-4111-8111-111111111111",
          provider_payment_ref: "428002",
          status: "created",
          fulfillment_status: "pending",
        });
      }

      if (url.endsWith("/transactions/428002")) {
        return jsonResponse({ status: "pending" });
      }

      if (url.includes("/rest/v1/rpc/update_payment_intent_status_if")) {
        return jsonResponse([]);
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request(
          "http://localhost/payments/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/verify",
          {
            method: "GET",
            headers: {
              authorization: "Bearer student-session-token",
            },
          },
        ),
      );

      assertEquals(response.status, 200);
      const body = await response.json();
      assertEquals(body.status, "pending");
      assertEquals(body.premium, false);

      const fedapayCall = calls.find((call) =>
        call.url.endsWith("/transactions/428002")
      );
      assertExists(
        fedapayCall,
        "Should have called FedaPay with provider_payment_ref",
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test(
  "GET /payments/{uuid}/verify with bearer token returns current status when no provider ref",
  async () => {
    const originalFetch = globalThis.fetch;

    globalThis.fetch = async (
      input: RequestInfo | URL,
      init?: RequestInit,
    ) => {
      const url = input instanceof Request
        ? input.url
        : input instanceof URL
        ? input.toString()
        : String(input);

      if (url.includes("/auth/v1/user")) {
        return jsonResponse({
          id: "11111111-1111-4111-8111-111111111111",
          email: "student@example.com",
        });
      }

      if (
        url.includes("/rest/v1/payment_intents") &&
        url.includes("cccccccc-cccc-4ccc-8ccc-cccccccccccc")
      ) {
        return jsonResponse({
          id: "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
          auth_user_id: "11111111-1111-4111-8111-111111111111",
          provider_payment_ref: null,
          status: "created",
          fulfillment_status: "pending",
        });
      }

      throw new Error(`Unexpected fetch call: ${url}`);
    };

    try {
      const response = await handler!(
        new Request(
          "http://localhost/payments/cccccccc-cccc-4ccc-8ccc-cccccccccccc/verify",
          {
            method: "GET",
            headers: {
              authorization: "Bearer student-session-token",
            },
          },
        ),
      );

      assertEquals(response.status, 200);
      const body = await response.json();
      assertEquals(body.status, "created");
      assertEquals(body.premium, false);
    } finally {
      globalThis.fetch = originalFetch;
    }
  },
);

Deno.test("POST /payments rejects invalid UUID as client_nonce", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse({
        id: "22222222-2222-4222-8222-222222222222",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium 90 jours",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: null,
        is_active: true,
      });
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse(null);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          client_nonce: "not-a-valid-uuid",
          customer: { phone: "+22990000000" },
          provider: "MTN",
        }),
      }),
    );

    assertEquals(response.status, 400);
    const body = await response.json();
    assertEquals(body.error.message, "client_nonce must be a valid UUID");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments returns 404 when product not found", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(true);
    }

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse(null);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "nonexistent_sku",
          customer: { phone: "+22990000000" },
          provider: "MTN",
        }),
      }),
    );

    assertEquals(response.status, 404);
    const body = await response.json();
    assertEquals(body.error.message, "Product not found");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("POST /payments returns 429 when rate limited", async () => {
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/auth/v1/user")) {
      return jsonResponse({
        id: "11111111-1111-4111-8111-111111111111",
        email: "student@example.com",
      });
    }

    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return jsonResponse(false);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  try {
    const response = await handler!(
      new Request("http://localhost/payments", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer student-session-token",
        },
        body: JSON.stringify({
          product_sku: "premium_lifetime",
          customer: { phone: "+22990000000" },
          provider: "MTN",
        }),
      }),
    );

    assertEquals(response.status, 429);
    const body = await response.json();
    assertExists(body.error);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
