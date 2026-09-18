import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const envValues = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-test-key",
  SUPABASE_SERVICE_ROLE_KEY: "service-role-test-key",
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

const defaultProducts = [
  {
    id: "prod-1",
    sku: "premium_lifetime",
    kind: "license_access",
    name: "Acces Premium 90 jours",
    amount_xof: 3000,
    currency: "XOF",
    premium_duration_days: 95,
    activation_code_quantity: null,
    package_name: null,
    is_active: true,
    code_prefix: null,
    metadata: {},
    created_at: "2026-04-28T15:02:08.16997+00",
    updated_at: "2026-04-28T15:02:08.16997+00",
  },
  {
    id: "prod-2",
    sku: "partner_pack_5",
    kind: "activation_pack",
    name: "Pack 5",
    amount_xof: 22500,
    currency: "XOF",
    premium_duration_days: 95,
    activation_code_quantity: 5,
    package_name: "Pack 5",
    is_active: true,
  },
];

const defaultContacts = [
  { key: "support_email", value: "support@codepermisbenin.com" },
  { key: "support_phone", value: "+229 56 26 26 26" },
  { key: "whatsapp_link", value: "https://wa.me/22956262626" },
  { key: "support_url", value: "https://codepermisbenin.com/support" },
];

function installFetchStub(options: { products?: unknown }) {
  const originalFetch = globalThis.fetch;
  const calls: string[] = [];

  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);
    calls.push(url);

    if (url.includes("/rest/v1/catalog_products")) {
      if (options.products !== undefined) {
        return jsonResponse(options.products);
      }
      return jsonResponse(defaultProducts);
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse([]);
    }

    if (url.includes("/rest/v1/company_contacts")) {
      return jsonResponse(defaultContacts);
    }

    if (url.includes("/rest/v1/app_config")) {
      return jsonResponse([]);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };

  return {
    calls,
    restore() {
      globalThis.fetch = originalFetch;
    },
  };
}

Deno.test("GET /config returns products and contacts", async () => {
  const stub = installFetchStub({});
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertExists(body.products);
    assertEquals(body.products.length, 2);
    assertEquals(body.products[0].sku, "premium_lifetime");
    assertExists(body.contacts);
    assertEquals(
      body.contacts.support_email,
      "support@codepermisbenin.com",
    );
    assertEquals(body.contacts.support_phone, "+229 56 26 26 26");
    assertEquals(
      body.contacts.whatsapp_link,
      "https://wa.me/22956262626",
    );
    assertEquals(
      body.contacts.support_url,
      "https://codepermisbenin.com/support",
    );
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config returns only active products", async () => {
  const stub = installFetchStub({
    products: [
      {
        id: "prod-1",
        sku: "premium_lifetime",
        kind: "license_access",
        name: "Acces Premium",
        amount_xof: 3000,
        currency: "XOF",
        premium_duration_days: 95,
        is_active: true,
      },
    ],
  });
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );

    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.products.length, 1);
    assertEquals(body.products[0].sku, "premium_lifetime");
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config rejects POST method", async () => {
  const stub = installFetchStub({});
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "POST",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );
    assertEquals(response.status, 405);
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config handles DB error", async () => {
  const stub = installFetchStub({
    products: null,
  });
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/rest/v1/catalog_products")) {
      return new Response(
        JSON.stringify({ error: "Database connection failed" }),
        { status: 500, headers: { "content-type": "application/json" } },
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );
    assertEquals(response.status, 500);
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config handles promotions DB error gracefully", async () => {
  const stub = installFetchStub({});
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse(defaultProducts);
    }

    if (url.includes("/rest/v1/promotions")) {
      return new Response(
        JSON.stringify({ message: "promotions query failed" }),
        { status: 500, headers: { "content-type": "application/json" } },
      );
    }

    if (url.includes("/rest/v1/company_contacts")) {
      return jsonResponse(defaultContacts);
    }

    if (url.includes("/rest/v1/app_config")) {
      return jsonResponse([]);
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );
    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.products.length, 2);
    assertEquals(body.products[0].sku, "premium_lifetime");
    assertEquals(body.products[1].sku, "partner_pack_5");
    assertEquals(body.products[0].promo_amount_xof, undefined);
    assertEquals(body.products[1].promo_name, undefined);
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config handles contacts DB error", async () => {
  const stub = installFetchStub({});
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse(defaultProducts);
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse([]);
    }

    if (url.includes("/rest/v1/company_contacts")) {
      return new Response(
        JSON.stringify({ message: "contacts query failed" }),
        { status: 500, headers: { "content-type": "application/json" } },
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );
    assertEquals(response.status, 500);
    const body = await response.json();
    assertEquals(typeof body.error, "string");
    assertEquals(body.error.includes("contacts"), true);
  } finally {
    stub.restore();
  }
});

Deno.test("GET /config fails open over app_config DB error", async () => {
  const stub = installFetchStub({});
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request
      ? input.url
      : input instanceof URL
      ? input.toString()
      : String(input);

    if (url.includes("/rest/v1/catalog_products")) {
      return jsonResponse(defaultProducts);
    }

    if (url.includes("/rest/v1/promotions")) {
      return jsonResponse([]);
    }

    if (url.includes("/rest/v1/company_contacts")) {
      return jsonResponse(defaultContacts);
    }

    if (url.includes("/rest/v1/app_config")) {
      return new Response(
        JSON.stringify({ message: "app_config query failed" }),
        { status: 500, headers: { "content-type": "application/json" } },
      );
    }

    throw new Error(`Unexpected fetch call: ${url}`);
  };
  try {
    const response = await handler!(
      new Request("http://localhost/config", {
        method: "GET",
        headers: { Authorization: "Bearer test-jwt" },
      }),
    );
    assertEquals(response.status, 200);
    const body = await response.json();
    assertEquals(body.app_config, {});
    assertEquals(typeof body.ttl_seconds, "number");
  } finally {
    stub.restore();
  }
});
