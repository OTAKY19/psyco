import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { HttpError } from "../_shared/errors.ts";
import { normalizeText } from "../_shared/validation.ts";
import { createRoleClient } from "../_shared/roles.ts";
import {
  extractBearerToken,
  normalizeProviderCode,
  normalizeTimestamp,
} from "../_shared/validation.ts";
import {
  computePremiumUntilIso,
  getAppScheme,
  getCurrentEnvironment,
} from "../_shared/fedapay.ts";
import { computePromoAmount, loadActivePromoForSku } from "../_shared/pricing.ts";
import { validatePartner as sharedValidatePartner } from "../_shared/partner_validation.ts";

export type CatalogProductRow = {
  id: string;
  sku: string;
  kind: string;
  name: string;
  amount_xof: number;
  currency: string;
  premium_duration_days: number | null;
  is_active: boolean;
  activation_code_quantity: number | null;
  package_name: string | null;
};

export type PaymentIntentRow = {
  id: string;
  auth_user_id: string;
  provider_payment_ref: string | null;
  status: string;
  fulfillment_status: string;
};

export type AuthenticatedStudent = {
  id: string;
  email?: string | null;
  phone?: string | null;
  is_anonymous?: boolean;
};

export type FulfillmentRow = {
  payment_intent_id?: string;
  product_kind?: string;
  premium_until?: string | null;
  fulfillment_status?: string;
};

export type ApplyPaidPaymentRow = {
  processed_once?: boolean;
  premium_until?: string | null;
  device_token?: string | null;
};

export type { PartnerValidation } from "../_shared/partner_validation.ts";



const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const FEDAPAY_CALLBACK_URL = Deno.env.get("FEDAPAY_CALLBACK_URL") ?? "";
const FEDAPAY_PAYMENT_INTENTS_CALLBACK_URL =
  Deno.env.get("FEDAPAY_PAYMENT_INTENTS_CALLBACK_URL") ?? "";

let _supabaseClient: SupabaseClient | null = null;

export async function getPaymentsClient(): Promise<SupabaseClient> {
  if (!_supabaseClient) {
    _supabaseClient = await createRoleClient("payments_processor");
  }
  return _supabaseClient;
}

const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

export function normalizeProductSku(value: unknown): string {
  const normalized = normalizeText(value).toLowerCase();
  if (!normalized) return "";
  return normalized.replace(/[^a-z0-9_-]/g, "");
}

export function normalizeIntentProvider(value: unknown): string {
  const normalized = normalizeProviderCode(value).toLowerCase();
  switch (normalized) {
    case "mtn":
    case "mtn_momo_ben":
      return "mtn";
    case "moov":
    case "moov_ben":
      return "moov";
    case "celtiis":
    case "celtiis_ben":
      return "celtiis";
    default:
      return "";
  }
}

function stripCallbackToken(url: string): string {
  try {
    const parsed = new URL(url);
    parsed.searchParams.delete("token");
    return parsed.toString();
  } catch {
    return url;
  }
}

export async function resolveSecureCallbackUrl(): Promise<string> {
  const envUrl = FEDAPAY_PAYMENT_INTENTS_CALLBACK_URL ||
    (FEDAPAY_CALLBACK_URL.includes("/payments/webhook")
      ? FEDAPAY_CALLBACK_URL.replace("/payments/webhook", "/payments_webhook")
      : FEDAPAY_CALLBACK_URL);
  if (envUrl) return stripCallbackToken(envUrl);
  const client = await getPaymentsClient();
  return getAppScheme(client);
}

export async function requireAuthenticatedStudent(
  req: Request,
): Promise<AuthenticatedStudent> {
  if (!SUPABASE_ANON_KEY) {
    throw new HttpError(500, "SUPABASE_ANON_KEY is required for JWT auth");
  }
  const token = extractBearerToken(req.headers.get("authorization"));
  if (!token) throw new HttpError(401, "Supabase bearer token required");
  const { data, error } = await authClient.auth.getUser(token);
  if (error || !data.user?.id) throw new HttpError(401, "Unauthorized");
  return data.user as AuthenticatedStudent;
}

export async function validatePartner(code?: string): Promise<PartnerValidation> {
  const client = await getPaymentsClient();
  return sharedValidatePartner(client, code);
}

export async function requireAuthenticatedPartner(
  req: Request,
): Promise<
  { userId: string; partnerId: string; partnerCode: string; userEmail?: string | null }
> {
  const user = await requireAuthenticatedStudent(req);
  const token = extractBearerToken(req.headers.get("authorization"));

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: partnerId, error: partnerError } = await userClient.rpc(
    "current_partner_id_for_auth_user",
  );
  if (partnerError || !partnerId) {
    throw new HttpError(
      403,
      "Compte partenaire requis. Lie d'abord ton profil partenaire a ton compte.",
    );
  }

  const pClient = await getPaymentsClient();
  const { data: partner, error: fetchError } = await pClient
    .from("partners")
    .select("id, code")
    .eq("id", partnerId)
    .single();

  if (fetchError || !partner) {
    throw new HttpError(403, "Partenaire introuvable.");
  }

  return {
    userId: user.id,
    partnerId: partner.id,
    partnerCode: partner.code,
    userEmail: user.email,
  };
}

export async function loadCatalogProduct(
  productSku: string,
): Promise<CatalogProductRow> {
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("catalog_products")
    .select(
      "id, name, sku, kind, amount_xof, currency, premium_duration_days, is_active, activation_code_quantity, package_name",
    )
    .eq("sku", productSku)
    .eq("is_active", true)
    .maybeSingle();
  if (error) throw new HttpError(500, "Failed catalog product lookup");
  if (!data) throw new HttpError(404, "Product not found");
  return data as CatalogProductRow;
}

export async function createPaymentIntent(
  values: Record<string, unknown>,
): Promise<PaymentIntentRow> {
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("payment_intents")
    .insert(values)
    .select("id, auth_user_id, provider_payment_ref, status, fulfillment_status")
    .single();
  if (error) {
    const pgError = error as
      & { code?: string; message?: string; details?: string; constraint?: string };
    const isUniqueViolation = pgError.code === "23505" &&
      (pgError.constraint === "payment_intents_client_nonce_key" ||
        (pgError.details && pgError.details.includes("client_nonce")) ||
        (pgError.message && pgError.message.includes("client_nonce")));
    if (isUniqueViolation && values.client_nonce) {
      const { data: existing, error: lookupError } = await client
        .from("payment_intents")
        .select("id, auth_user_id, provider_payment_ref, status, fulfillment_status")
        .eq("client_nonce", values.client_nonce)
        .maybeSingle();
      if (!lookupError && existing) {
        const expectedUserId = values.auth_user_id as string | undefined;
        if (expectedUserId && existing.auth_user_id !== expectedUserId) {
          throw new HttpError(409, "client_nonce belongs to another user");
        }
        return existing as PaymentIntentRow;
      }
    }
    throw new HttpError(500, "Failed payment intent insert");
  }
  return data as PaymentIntentRow;
}

export async function updatePaymentIntent(
  id: string,
  values: Record<string, unknown>,
) {
  const client = await getPaymentsClient();
  const { error } = await client
    .from("payment_intents")
    .update(values)
    .eq("id", id);
  if (error) throw new HttpError(500, "Failed payment intent update");
}

export async function findPendingDeviceIntent(
  deviceId: string,
): Promise<{ id: string; provider_payment_ref: string | null; status: string } | null> {
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("payment_intents")
    .select("id, provider_payment_ref, status")
    .eq("device_id", deviceId)
    .eq("status", "created")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) {
    console.error("[payments] findPendingDeviceIntent failed:", error);
    return null;
  }
  return data as { id: string; provider_payment_ref: string | null; status: string } | null;
}

export async function createAnonymousPaymentIntent(
  deviceId: string,
  provider: string,
  amount: number,
  currency: string,
  promotionId?: string,
): Promise<PaymentIntentRow & { id: string }> {
  const premiumProduct = await loadCatalogProduct("premium_lifetime");
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("payment_intents")
    .insert({
      auth_user_id: null,
      device_id: deviceId,
      product_id: premiumProduct.id,
      provider: provider || "mtn",
      client_nonce: crypto.randomUUID(),
      phone_e164: null,
      amount_xof: Math.floor(amount),
      currency,
      promotion_id: promotionId ?? null,
      environment: getCurrentEnvironment(),
      status: "created",
      fulfillment_status: "pending",
      raw_metadata: { source: "legacy_app_token", device_id: deviceId },
    })
    .select("id, auth_user_id, provider_payment_ref, status, fulfillment_status")
    .single();
  if (error) throw new HttpError(500, "Failed anonymous payment intent");
  return data as PaymentIntentRow & { id: string };
}

export async function loadOwnPaymentIntent(
  paymentIntentId: string,
  userId: string,
): Promise<PaymentIntentRow> {
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("payment_intents")
    .select("id, auth_user_id, provider_payment_ref, status, fulfillment_status")
    .eq("id", paymentIntentId)
    .eq("auth_user_id", userId)
    .maybeSingle();
  if (error) throw new HttpError(500, "Failed payment intent lookup");
  if (!data) throw new HttpError(404, "Payment intent not found");
  return data as PaymentIntentRow;
}

export async function loadActiveAccessGrant(
  userId: string,
  paymentIntentId: string,
) {
  const client = await getPaymentsClient();
  const { data, error } = await client
    .from("user_access_grants")
    .select("ends_at,status")
    .eq("auth_user_id", userId)
    .eq("payment_intent_id", paymentIntentId)
    .eq("status", "active")
    .maybeSingle();
  if (error) throw new HttpError(500, "Failed access grant lookup");
  return data as { ends_at?: string | null; status?: string } | null;
}

export async function fulfillPaymentIntent(
  paymentIntentId: string,
): Promise<FulfillmentRow | null> {
  const client = await getPaymentsClient();
  const { data, error } = await client.rpc("fulfill_payment_intent", {
    p_payment_intent_id: paymentIntentId,
  });
  if (error) throw new HttpError(500, "Failed payment fulfillment");

  // Record promo redemption if applicable
  try {
    await recordPromoRedemption(paymentIntentId);
  } catch (e) {
    console.error(
      "[payments/db] Failed to record promo redemption for intent",
      paymentIntentId,
      e,
    );
  }

  return (Array.isArray(data) ? data[0] : data) as FulfillmentRow | null;
}

async function recordPromoRedemption(paymentIntentId: string) {
  const client = await getPaymentsClient();
  const { data: intent, error } = await client
    .from("payment_intents")
    .select("promotion_id, product_id, auth_user_id, partner_id")
    .eq("id", paymentIntentId)
    .maybeSingle();

  if (error) {
    console.error("Error fetching payment intent for promo recording:", error);
    return;
  }
  if (!intent || !intent.promotion_id) return;

  const { data: product } = await client
    .from("catalog_products")
    .select("sku")
    .eq("id", intent.product_id)
    .maybeSingle();

  if (!product) return;

  const buyerType = intent.partner_id ? "partner" : "student";
  const buyerId = intent.partner_id ?? intent.auth_user_id ?? null;

  const { error: insertError } = await client
    .from("promotion_redemptions")
    .insert({
      promotion_id: intent.promotion_id,
      payment_intent_id: paymentIntentId,
      sku: product.sku,
      buyer_type: buyerType,
      buyer_id: buyerId,
    });

  if (insertError && insertError.code === "23505") {
    // Duplicate - already recorded, that's fine
    return;
  }
  if (insertError) {
    throw insertError;
  }
}

export async function applyPaidPayment(
  paymentId: string,
  deviceId: string,
  rawPayload: Record<string, unknown>,
) {
  const PRICE_XOF = Number(Deno.env.get("PRICE_XOF") ?? "3000");
  const premiumProduct = await loadCatalogProduct("premium_lifetime");
  const durationDays = premiumProduct?.premium_duration_days ?? null;
  const premiumUntilIso = computePremiumUntilIso(durationDays);
  const client = await getPaymentsClient();
  const { data, error } = await client.rpc("apply_paid_payment", {
    p_payment_id: paymentId,
    p_device_id: deviceId,
    p_amount: Math.floor(premiumProduct.amount_xof ?? PRICE_XOF),
    p_premium_until: premiumUntilIso,
    p_raw_payload: rawPayload,
  });
  if (error) throw new HttpError(500, "Failed payment application");
  const row = (Array.isArray(data) ? data[0] : data) as ApplyPaidPaymentRow | null;
  return {
    processedOnce: row?.processed_once === true,
    premiumUntil: normalizeTimestamp(row?.premium_until) ?? premiumUntilIso,
    deviceToken: row?.device_token ?? null,
  };
}

export type RedeemActivationCodeRow = {
  activation_code_id?: string;
  product_sku?: string;
  premium_until?: string | null;
  status?: string;
};

export async function redeemActivationCodeForUser(
  authUserId: string,
  code: string,
): Promise<RedeemActivationCodeRow | null> {
  const client = await getPaymentsClient();
  const { data, error } = await client.rpc("redeem_activation_code_for_user", {
    p_code: code,
    p_auth_user_id: authUserId,
  });
  if (error) throw new HttpError(500, "Failed activation code redemption");
  return (Array.isArray(data) ? data[0] : data) as RedeemActivationCodeRow | null;
}
