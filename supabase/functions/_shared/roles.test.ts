import {
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { _resetRoleEnvForTesting } from "./roles.ts";

// Module cache bust : roles.ts caches env at module load. Re-import with a
// unique query string so each test evaluates ensureEnv() against the env we set.
function freshRoles() {
  _resetRoleEnvForTesting();
  return import(`./roles.ts?bust=${crypto.randomUUID()}`);
}

Deno.test({
  name: "createRoleClient throws MISCONFIG when CUSTOM_ROLES_ENABLED but JWT_SECRET missing",
  async fn() {
    const prevSecret = Deno.env.get("JWT_SECRET");
    const prevFlag = Deno.env.get("CUSTOM_ROLES_ENABLED");
    const prevUrl = Deno.env.get("SUPABASE_URL");
    const prevKey = Deno.env.get("SUPABASE_ANON_KEY");
    const prevSrk = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    try {
      Deno.env.set("JWT_SECRET", "");
      Deno.env.set("CUSTOM_ROLES_ENABLED", "true");
      Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
      Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");
      Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "");
      const { createRoleClient } = await freshRoles();
      await assertRejects(
        () => createRoleClient("premium_checker"),
        Error,
        "JWT_SECRET",
      );
    } finally {
      if (prevSecret) Deno.env.set("JWT_SECRET", prevSecret);
      Deno.env.delete("CUSTOM_ROLES_ENABLED");
      if (prevUrl) Deno.env.set("SUPABASE_URL", prevUrl);
      if (prevKey) Deno.env.set("SUPABASE_ANON_KEY", prevKey);
      if (prevSrk) Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", prevSrk);
    }
  },
  sanitizeResources: false,
  sanitizeOps: false,
});

Deno.test({
  name: "createRoleClient throws MISCONFIG when SUPABASE_URL missing",
  async fn() {
    const prevUrl = Deno.env.get("SUPABASE_URL");
    const prevKey = Deno.env.get("SUPABASE_ANON_KEY");
    const prevSrk = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    try {
      Deno.env.set("JWT_SECRET", "test-secret-of-sufficient-length!!");
      Deno.env.set("SUPABASE_URL", "");
      Deno.env.set("SUPABASE_ANON_KEY", "test-key");
      Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "");
      const { createRoleClient } = await freshRoles();
      await assertRejects(
        () => createRoleClient("payments_processor"),
        Error,
        "SUPABASE_URL",
      );
    } finally {
      if (prevUrl) Deno.env.set("SUPABASE_URL", prevUrl);
      if (prevKey) Deno.env.set("SUPABASE_ANON_KEY", prevKey);
      if (prevSrk) Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", prevSrk);
    }
  },
  sanitizeResources: false,
  sanitizeOps: false,
});
