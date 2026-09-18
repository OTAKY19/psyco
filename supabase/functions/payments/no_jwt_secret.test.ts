import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "anon-test-key");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-role-test-key");
Deno.env.set("FEDAPAY_API_TOKEN", "fedapay-test-token");
Deno.env.set("PAYMENT_APP_TOKEN", "payment-app-test-token");
Deno.env.set("PREMIUM_DURATION_DAYS", "95");
Deno.env.delete("JWT_SECRET");

let handler: ((req: Request) => Promise<Response>) | null = null;
Object.defineProperty(Deno, "serve", {
  value: (serveHandler: (req: Request) => Promise<Response>) => {
    handler = serveHandler;
    return { close() {} };
  },
  configurable: true,
});

await import("./index.ts");

if (!handler) throw new Error("Handler not captured");

Deno.test("payments starts without JWT_SECRET (service_role fallback)", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response("{}", { status: 200 });
  try {
    const res = await handler!(
      new Request("https://example.supabase.co/payments", {
        method: "POST",
        headers: {
          "x-app-token": "payment-app-test-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({ action: "verify_app_token" }),
      }),
    );
    const text = await res.text();
    assertEquals(text.includes("Missing env: JWT_SECRET"), false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
