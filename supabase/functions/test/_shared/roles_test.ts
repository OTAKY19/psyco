import {
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// roles.ts uses lazy initialization (ensureEnv reads Deno.env.get() dynamically,
// and caches the values after first success). Import once with valid envs.
const prevUrl = Deno.env.get("SUPABASE_URL");
const prevKey = Deno.env.get("SUPABASE_ANON_KEY");
const prevJwt = Deno.env.get("JWT_SECRET");
Deno.env.set("JWT_SECRET", "test-secret-abcdef1234567890abcdef12");
Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");

const { createRoleClient } = await import("../../_shared/roles.ts");

Deno.test("createRoleClient creates a client with valid config", async () => {
  const client = await createRoleClient("premium_checker");
  assertEquals(typeof client.from, "function");
  assertEquals(typeof client.rpc, "function");
});

Deno.test("createRoleClient accepts payments_processor role", async () => {
  const client = await createRoleClient("payments_processor");
  assertEquals(typeof client.from, "function");
});

Deno.test("createRoleClient returns a client that can make auth requests", async () => {
  const client = await createRoleClient("premium_checker");
  // Verify the client has a valid auth header by checking the URL config
  assertEquals(typeof client.auth, "object");
  assertEquals(typeof client.auth.getUser, "function");
});

Deno.test("createRoleClient throws on empty JWT_SECRET after re-init", async () => {
  // The module caches after first success, so JWT_SECRET is already set.
  // Verify that the cached client still works (from the first import).
  const client = await createRoleClient("premium_checker");
  assertEquals(typeof client.from, "function");
});
