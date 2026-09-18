import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { HttpError } from "./errors.ts";

let cachedClient: ReturnType<typeof createClient> | null = null;

function getSupabaseClient() {
  if (cachedClient) return cachedClient;
  // Read env lazily so misconfiguration is detected at call time (and tests
  // can toggle env between runs) while still memoizing the client per process.
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL) {
    throw new Error("[MISCONFIG] SUPABASE_URL is required for rate limiting");
  }
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("[MISCONFIG] SUPABASE_SERVICE_ROLE_KEY is required for rate limiting");
  }
  cachedClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cachedClient;
}

export async function checkRateLimit(
  bucket: string,
  key: string,
  maxAttempts = 10,
  windowSeconds = 60,
): Promise<void> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase.rpc("check_rate_limit", {
    p_bucket: bucket,
    p_key: key,
    p_max_attempts: maxAttempts,
    p_window_seconds: windowSeconds,
  });

  if (error) {
    console.error(`Rate limit check failed for ${bucket}/${key}: ${error.message}`);
    throw new HttpError(500, "Erreur interne lors de la vérification du taux.");
  }

  if (data === false) {
    throw new HttpError(
      429,
      `Trop de tentatives. Réessayez dans ${windowSeconds} secondes.`,
    );
  }
}

