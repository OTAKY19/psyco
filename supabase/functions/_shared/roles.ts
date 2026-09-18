import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT } from "https://esm.sh/jose@5";

export type RoleName = "premium_checker" | "payments_processor";

let _jwtSecret: Uint8Array | null = null;
let _supabaseUrl: string | null = null;
let _supabaseAnonKey: string | null = null;
let _supabaseServiceRoleKey: string | null = null;
let _customRolesEnabled: boolean | null = null;

// Test-only helper : reset the cached env so ensureEnv() re-reads Deno.env.
// Without this, module-level caching makes sequential tests share stale state.
export function _resetRoleEnvForTesting() {
  _jwtSecret = null;
  _supabaseUrl = null;
  _supabaseAnonKey = null;
  _supabaseServiceRoleKey = null;
  _customRolesEnabled = null;
}

function ensureEnv() {
  if (_jwtSecret && _customRolesEnabled !== null) return;
  const raw = Deno.env.get("JWT_SECRET");
  if (raw) {
    _jwtSecret = new TextEncoder().encode(raw);
  }
  _supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  _supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  _supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!_supabaseUrl || !_supabaseAnonKey) {
    throw new Error(
      "[MISCONFIG] Missing SUPABASE_URL or SUPABASE_ANON_KEY for createRoleClient().",
    );
  }
  // Custom DB roles (premium_checker / payments_processor) require a Supabase
  // Pro plan. On lower plans those roles do not exist, so we fall back to the
  // service role key (read/write bypassing RLS) which keeps check_premium,
  // payments and link_device_premium working. Set CUSTOM_ROLES_ENABLED=true
  // once the roles + custom API keys are provisioned.
  const flag = Deno.env.get("CUSTOM_ROLES_ENABLED");
  const wantsCustomRoles = flag === "true";
  _customRolesEnabled = wantsCustomRoles && _jwtSecret !== null;
  if (wantsCustomRoles && !_jwtSecret) {
    throw new Error(
      "[MISCONFIG] CUSTOM_ROLES_ENABLED=true requires JWT_SECRET to sign " +
        "custom-role JWTs. Set JWT_SECRET (same as SUPABASE_JWT_SECRET) or " +
        "disable custom roles (CUSTOM_ROLES_ENABLED=false).",
    );
  }
  if (!_customRolesEnabled && !_supabaseServiceRoleKey) {
    throw new Error(
      "[MISCONFIG] Custom roles are disabled but SUPABASE_SERVICE_ROLE_KEY is " +
        "missing. Either set CUSTOM_ROLES_ENABLED=true with JWT_SECRET (Pro plan) " +
        "or provide SUPABASE_SERVICE_ROLE_KEY as a fallback.",
    );
  }
}

export async function createRoleClient(role: RoleName) {
  ensureEnv();

  // Fallback path: on non-Pro plans the custom DB roles do not exist, so we use
  // the service role key directly. This keeps the role-based Edge Functions
  // functional without provisioning custom API keys.
  if (!_customRolesEnabled) {
    return createClient(_supabaseUrl!, _supabaseServiceRoleKey!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }

  const jwt = await new SignJWT({ role })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuer("supabase")
    .setIssuedAt()
    .setExpirationTime("60m")
    .sign(_jwtSecret!);

  return createClient(_supabaseUrl!, _supabaseAnonKey!, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
