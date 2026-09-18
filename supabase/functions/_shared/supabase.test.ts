import {
  assertExists,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// supabase.ts reads env at call time (lazy), so env must be set before use.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key");

const { getSupabaseUrl, serviceRoleClient, anonClient, createUserClient } =
  await import("./supabase.ts");

Deno.test("getSupabaseUrl returns the configured URL", () => {
  assertEquals(getSupabaseUrl(), "https://example.supabase.co");
});

Deno.test("anonClient builds a client with the anon key", () => {
  const client = anonClient();
  assertExists(client);
  // The anon key is embedded in the client's auth headers.
  assertEquals(
    (client as unknown as { supabaseKey: string }).supabaseKey,
    "test-anon-key",
  );
});

Deno.test("serviceRoleClient builds a client with the service role key", () => {
  const client = serviceRoleClient();
  assertExists(client);
  assertEquals(
    (client as unknown as { supabaseKey: string }).supabaseKey,
    "test-service-role-key",
  );
});

Deno.test("createUserClient embeds the provided access token", () => {
  const client = createUserClient("user-jwt-token");
  assertExists(client);
  const headers = (client as unknown as {
    auth: { headers: Record<string, string> };
  }).auth.headers;
  assertEquals(headers["Authorization"], "Bearer user-jwt-token");
});
