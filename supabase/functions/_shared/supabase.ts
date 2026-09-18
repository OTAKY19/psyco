import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

let _envReady = false;
let _supabaseUrl = "";
let _supabaseAnonKey = "";
let _supabaseServiceRoleKey = "";

function ensureEnv() {
  if (_envReady) return;
  _supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  _supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  _supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!_supabaseUrl || !_supabaseAnonKey) {
    throw new Error(
      "[MISCONFIG] Missing SUPABASE_URL or SUPABASE_ANON_KEY for Supabase client helpers.",
    );
  }
  _envReady = true;
}

/** The project's Supabase URL (throws if unset). */
export function getSupabaseUrl(): string {
  ensureEnv();
  return _supabaseUrl;
}

/** A service-role client that bypasses RLS. Keep server-side only. */
export function serviceRoleClient(): SupabaseClient {
  ensureEnv();
  if (!_supabaseServiceRoleKey) {
    throw new Error(
      "[MISCONFIG] SUPABASE_SERVICE_ROLE_KEY is required for serviceRoleClient().",
    );
  }
  return createClient(_supabaseUrl, _supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** An anonymous client (public schema, subject to RLS). */
export function anonClient(): SupabaseClient {
  ensureEnv();
  return createClient(_supabaseUrl, _supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** A client authenticated as a specific user via their access token. */
export function createUserClient(accessToken: string): SupabaseClient {
  ensureEnv();
  return createClient(_supabaseUrl, _supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
