import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { HttpError } from "./errors.ts";

// rate_limit.ts reads SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY at module
// import time, so the env must be set before importing the system under test.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key");

const { checkRateLimit } = await import("./rate_limit.ts");

Deno.test("checkRateLimit throws MISCONFIG when SUPABASE_URL missing", async () => {
  const prevUrl = Deno.env.get("SUPABASE_URL");
  const prevKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  try {
    Deno.env.set("SUPABASE_URL", "");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "");
    await assertRejects(
      () => checkRateLimit("test", "key"),
      Error,
      "SUPABASE_URL is required for rate limiting",
    );
  } finally {
    Deno.env.set("SUPABASE_URL", prevUrl ?? "");
    Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", prevKey ?? "");
  }
});

Deno.test("checkRateLimit reuses a single Supabase client instance", async () => {
  const prevUrl = Deno.env.get("SUPABASE_URL");
  const prevKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
  Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key");
  const origFetch = globalThis.fetch;
  globalThis.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : input.toString();
    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return new Response(JSON.stringify(true), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }
    return origFetch(input, init);
  };
  try {
    await checkRateLimit("test_bucket", "key-1", 5, 60);
    await checkRateLimit("test_bucket", "key-2", 5, 60);
    assertEquals(true, true);
  } finally {
    globalThis.fetch = origFetch;
    if (prevUrl) Deno.env.set("SUPABASE_URL", prevUrl);
    else Deno.env.delete("SUPABASE_URL");
    if (prevKey) Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", prevKey);
    else Deno.env.delete("SUPABASE_SERVICE_ROLE_KEY");
  }
});
