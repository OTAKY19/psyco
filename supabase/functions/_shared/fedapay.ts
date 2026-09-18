import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { HttpError } from "./errors.ts";
import { asRecord, normalizeText } from "./validation.ts";

export type FedaPayCreatePayload = {
  amount: number;
  currency: string;
  description: string;
  callbackUrl?: string;
  mode?: string;
  customer: Record<string, unknown>;
  customMetadata: Record<string, string>;
};

export type FedaPayPhoneNumber = {
  number: string;
  country: string;
};

const PROVIDER_TO_NO_REDIRECT_MODE: Record<string, string> = {
  MTN_MOMO_BEN: "mtn",
  MTN: "mtn",
  MOOV_BEN: "moov",
  MOOV: "moov",
  CELTIIS_BEN: "celtiis",
  CELTIIS: "celtiis",
};

export type FedaPayConfig = {
  apiUrl: string;
  apiToken: string;
  environment: 'sandbox' | 'live';
};

let _fedapayConfig: FedaPayConfig | null = null;

/** NOTE: lit le cache uniquement. Pour une lecture fraîche de la DB, utiliser
 *  `await refreshFedaPayConfig()` d'abord, ou la fonction homonyme dans
 *  `admin_partners/_shared.ts`. */
export function getCurrentEnvironment(): 'sandbox' | 'live' {
  if (_fedapayConfig) return _fedapayConfig.environment;
  return (Deno.env.get("FEDAPAY_MODE") ?? "live") as 'sandbox' | 'live';
}

export async function refreshFedaPayConfig(supabaseClient: SupabaseClient): Promise<FedaPayConfig> {
  try {
    const { data } = await supabaseClient
      .from("app_config")
      .select("value")
      .eq("key", "fedapay_mode")
      .maybeSingle();
    const mode: 'sandbox' | 'live' = (data?.value ?? Deno.env.get("FEDAPAY_MODE") ?? "live") as 'sandbox' | 'live';
    _fedapayConfig = {
      apiUrl: mode === "sandbox"
        ? Deno.env.get("FEDAPAY_SANDBOX_API_URL") ??
          "https://sandbox-api.fedapay.com/v1"
        : (Deno.env.get("FEDAPAY_API_URL") || "https://api.fedapay.com/v1"),
      apiToken: mode === "sandbox"
        ? (Deno.env.get("FEDAPAY_SANDBOX_TOKEN") ?? "")
        : (Deno.env.get("FEDAPAY_API_TOKEN") ??
          Deno.env.get("CLE_SECRETE") ?? ""),
      environment: mode,
    };
    return _fedapayConfig;
  } catch (err) {
    console.error("[refreshFedaPayConfig] DB error, falling back to env:", err);
    _fedapayConfig = null;
    const fallbackMode: 'sandbox' | 'live' = (Deno.env.get("FEDAPAY_MODE") ?? "live") as 'sandbox' | 'live';
    return {
      apiUrl: fallbackMode === "sandbox"
        ? "https://sandbox-api.fedapay.com/v1"
        : "https://api.fedapay.com/v1",
      apiToken: fallbackMode === "sandbox"
        ? (Deno.env.get("FEDAPAY_SANDBOX_TOKEN") ?? "")
        : (Deno.env.get("FEDAPAY_API_TOKEN") ?? Deno.env.get("CLE_SECRETE") ?? ""),
      environment: fallbackMode,
    };
  }
}

function getApiUrl(): string {
  if (_fedapayConfig) return _fedapayConfig.apiUrl;
  const mode = Deno.env.get("FEDAPAY_MODE") ?? "live";
  const envUrl = Deno.env.get("FEDAPAY_API_URL");
  if (envUrl) return envUrl.replace(/\/+$/, "");
  return mode === "sandbox"
    ? "https://sandbox-api.fedapay.com/v1"
    : "https://api.fedapay.com/v1";
}

function getApiToken(): string {
  if (_fedapayConfig) return _fedapayConfig.apiToken;
  const mode = Deno.env.get("FEDAPAY_MODE") ?? "live";
  if (mode === "sandbox") {
    return Deno.env.get("FEDAPAY_SANDBOX_TOKEN") ?? "";
  }
  return Deno.env.get("FEDAPAY_API_TOKEN") ??
    Deno.env.get("CLE_SECRETE") ?? "";
}

function buildFedaPayHeaders() {
  return {
    Authorization: `Bearer ${getApiToken()}`,
    "Content-Type": "application/json",
  };
}

async function parseJsonUnknown(response: Response): Promise<unknown> {
  return await response.json().catch(() => null);
}

async function parseJsonObject(
  response: Response,
): Promise<Record<string, unknown>> {
  const parsed = await parseJsonUnknown(response);
  return asRecord(parsed);
}

function firstObjectFromUnknown(value: unknown): Record<string, unknown> {
  if (Array.isArray(value)) {
    for (const item of value) {
      const record = asRecord(item);
      if (Object.keys(record).length) return record;
    }
    return {};
  }
  return asRecord(value);
}

function extractTransactionObject(
  value: Record<string, unknown>,
): Record<string, unknown> {
  const candidates = [
    value["v1/transaction"],
    value.transaction,
    value.data,
    value,
  ];
  for (const candidate of candidates) {
    const record = firstObjectFromUnknown(candidate);
    if (Object.keys(record).length) return record;
  }
  return {};
}

function extractFailureMessage(payload: Record<string, unknown>): string {
  const direct = normalizeText(payload.message) ||
    normalizeText(payload.error) ||
    normalizeText(payload.detail);
  if (direct) return direct;
  const lastErrorCode = normalizeText(payload.last_error_code);
  if (lastErrorCode) return `FedaPay error: ${lastErrorCode}`;
  const nestedData = asRecord(payload.data);
  if (Object.keys(nestedData).length) return extractFailureMessage(nestedData);
  return "";
}

export const DEFAULT_LIFETIME_DAYS = 36500;
export const DEFAULT_APP_SCHEME = "psyco://app/payment/callback";

export function computePremiumUntilIso(durationDays?: number | null) {
  const days = durationDays ?? Number(
    Deno.env.get("PREMIUM_DURATION_DAYS") ?? String(DEFAULT_LIFETIME_DAYS),
  );
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + Math.floor(days));
  return date.toISOString();
}

export async function getAppScheme(client: SupabaseClient): Promise<string> {
  try {
    const { data } = await client
      .from("app_config")
      .select("value")
      .eq("key", "payment_scheme")
      .maybeSingle();
    return normalizeText(data?.value) || DEFAULT_APP_SCHEME;
  } catch (err) {
    console.error("[getAppScheme] DB error, falling back to default:", err);
    return DEFAULT_APP_SCHEME;
  }
}

function toUpperCode(value: unknown): string {
  const normalized = normalizeText(value).toUpperCase();
  return /^[A-Z]{2,5}$/.test(normalized) ? normalized : "";
}

export function normalizeCurrency(value: unknown): string {
  return toUpperCode(value) || "XOF";
}

export function normalizeCountryIso3(value: unknown): string {
  const code = toUpperCode(value);
  if (code.length === 2) {
    if (code === "BJ") return "BEN";
    return code;
  }
  if (code.length === 3) return code;
  return "BEN";
}

export function countryIso3ToIso2(value: string): string {
  const normalized = value.toUpperCase();
  if (normalized === "BEN") return "BJ";
  if (normalized.length === 2) return normalized;
  return "BJ";
}

export function normalizePhoneE164(phone: unknown, countryIso3: string): string {
  const raw = normalizeText(phone);
  const digits = raw.replace(/\D+/g, "");
  if (!digits) return "";
  if (raw.startsWith("+") && /^[1-9][0-9]{7,14}$/.test(digits)) return `+${digits}`;
  if (digits.startsWith("229") && /^[1-9][0-9]{7,14}$/.test(digits)) return `+${digits}`;
  if (countryIso3ToIso2(countryIso3) === "BJ") {
    const beninDigits = `229${digits}`;
    if (/^[1-9][0-9]{7,14}$/.test(beninDigits)) return `+${beninDigits}`;
  }
  if (/^[1-9][0-9]{7,14}$/.test(digits)) return `+${digits}`;
  return "";
}

export function sanitizePhoneNumber(phone: unknown): string {
  const digits = normalizeText(phone).replace(/\D+/g, "");
  if (!digits) return "";
  if (digits.startsWith("229") && digits.length >= 11) return digits.slice(3);
  return digits;
}

export function resolveNoRedirectMode(providerCode: string): string {
  if (!providerCode) return "";
  return PROVIDER_TO_NO_REDIRECT_MODE[providerCode] ?? "";
}

export function normalizeMetadata(raw: unknown): Record<string, string> {
  if (!raw) return {};
  const merged: Record<string, string> = {};
  const objectEntry = asRecord(raw);
  for (const [key, value] of Object.entries(objectEntry)) {
    const normalizedKey = key.trim();
    if (!normalizedKey) continue;
    if (
      typeof value === "string" || typeof value === "number" ||
      typeof value === "boolean"
    ) {
      const normalizedValue = String(value).trim();
      if (normalizedValue) merged[normalizedKey] = normalizedValue;
    }
  }
  return merged;
}

export function pickMetadataValue(
  metadata: Record<string, string>,
  keys: string[],
): string {
  for (const key of keys) {
    const value = normalizeText(metadata[key]);
    if (value) return value;
  }
  return "";
}

function buildCustomer(
  customerRaw: Record<string, unknown>,
  countryIso3: string,
): Record<string, unknown> {
  const email = normalizeText(customerRaw.email);
  const firstName = normalizeText(customerRaw.firstName) ||
    normalizeText(customerRaw.firstname);
  const lastName = normalizeText(customerRaw.lastName) ||
    normalizeText(customerRaw.lastname);
  const phone = sanitizePhoneNumber(customerRaw.phone);
  const countryIso2 = countryIso3ToIso2(countryIso3);
  const customer: Record<string, unknown> = {};
  if (email) customer.email = email;
  if (firstName) customer.firstname = firstName;
  if (lastName) customer.lastname = lastName;
  if (phone) {
    customer.phone_number = { number: phone, country: countryIso2 };
  }
  return customer;
}

export async function createFedaPayTransaction(payload: FedaPayCreatePayload) {
  const body: Record<string, unknown> = {
    description: payload.description,
    amount: Math.floor(payload.amount),
    currency: { iso: payload.currency },
    customer: payload.customer,
    custom_metadata: payload.customMetadata,
  };
  if (payload.callbackUrl) body.callback_url = payload.callbackUrl;
  if (payload.mode) body.mode = payload.mode;

  const createResponse = await fetch(`${getApiUrl()}/transactions`, {
    method: "POST",
    headers: buildFedaPayHeaders(),
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15000),
  });
  const createJson = await parseJsonObject(createResponse);
  if (!createResponse.ok) {
    const message = extractFailureMessage(createJson) ||
      "FedaPay transaction creation failed";
    throw new HttpError(502, message);
  }

  const transaction = extractTransactionObject(createJson);
  const transactionId = Number(transaction.id ?? createJson.id);
  if (!Number.isFinite(transactionId)) {
    throw new HttpError(502, "FedaPay transaction id missing in create response");
  }

  const reference = normalizeText(transaction.reference ?? createJson.reference);
  const status = normalizeText(transaction.status ?? createJson.status)
    .toLowerCase() || "pending";
  const checkoutUrl = normalizeText(
    transaction.payment_url ?? transaction.checkout_url ?? transaction.url ??
      createJson.payment_url ?? createJson.checkout_url ?? createJson.url,
  );
  const token = normalizeText(
    transaction.payment_token ?? transaction.token ??
      createJson.payment_token ?? createJson.token,
  );

  if (checkoutUrl && token) {
    return {
      transactionId, reference, status, checkoutUrl, token,
      raw: { create: createJson, transaction },
    };
  }

  const tokenResponse = await fetch(
    `${getApiUrl()}/transactions/${transactionId}/token`,
    { method: "POST", headers: buildFedaPayHeaders(), signal: AbortSignal.timeout(15000) },
  );
  const tokenJson = await parseJsonObject(tokenResponse);
  if (!tokenResponse.ok) {
    const message = extractFailureMessage(tokenJson) ||
      "FedaPay checkout token generation failed";
    throw new HttpError(502, message);
  }

  const fallbackCheckoutUrl = normalizeText(tokenJson.url);
  const fallbackToken = normalizeText(tokenJson.token);
  if (!fallbackCheckoutUrl) throw new HttpError(502, "FedaPay checkout URL missing");
  if (!fallbackToken) throw new HttpError(502, "FedaPay token missing");

  return {
    transactionId, reference, status,
    checkoutUrl: fallbackCheckoutUrl, token: fallbackToken,
    raw: { create: createJson, token: tokenJson },
  };
}

export async function sendFedaPayNoRedirectPayment(
  mode: string,
  token: string,
  phoneNumber?: FedaPayPhoneNumber,
) {
  const body: Record<string, unknown> = { token };
  if (phoneNumber && phoneNumber.number) {
    body.phone_number = { number: phoneNumber.number, country: phoneNumber.country };
  }
  const response = await fetch(
    `${getApiUrl()}/transactions/${encodeURIComponent(mode)}`,
    { method: "POST", headers: buildFedaPayHeaders(), body: JSON.stringify(body), signal: AbortSignal.timeout(15000) },
  );
  const jsonUnknown = await parseJsonUnknown(response);
  const jsonRecord = firstObjectFromUnknown(jsonUnknown);
  if (!response.ok) {
    const message = extractFailureMessage(jsonRecord) ||
      "FedaPay no-redirect payment initiation failed";
    throw new HttpError(502, message);
  }
  return {
    status: normalizeText(jsonRecord.status).toLowerCase() || "pending",
    raw: jsonUnknown,
  };
}

export async function fetchFedaPayTransaction(transactionId: string) {
  const response = await fetch(
    `${getApiUrl()}/transactions/${encodeURIComponent(transactionId)}`,
    { method: "GET", headers: buildFedaPayHeaders(), signal: AbortSignal.timeout(15000) },
  );
  const json = await parseJsonObject(response);
  if (response.status === 404) {
    return { status: "not_found", raw: json, data: {} as Record<string, unknown> };
  }
  if (!response.ok) {
    const message = extractFailureMessage(json) ||
      "Failed to fetch FedaPay transaction status";
    throw new HttpError(502, message);
  }
  const status = normalizeText(json.status).toLowerCase() || "unknown";
  return { status, raw: json, data: json };
}

export function mapFedaStatusToInternal(status: string): string {
  switch (status) {
    case "approved":
    case "transferred":
      return "completed";
    case "pending":
      return "pending";
    case "declined":
    case "canceled":
    case "deleted":
    case "refunded":
    case "expired":
      return "failed";
    case "not_found":
      return "not_found";
    default:
      return "pending";
  }
}

export function mapInternalStatusToPaymentIntentStatus(status: string): string {
  switch (status) {
    case "completed":
      return "completed";
    case "failed":
    case "not_found":
      return "failed";
    case "pending":
    default:
      return "pending";
  }
}

async function verifyFedaPayWebhookSignature(
  body: string,
  signatureHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader || !secret) {
    return false;
  }

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(body),
  );

  const expected = btoa(String.fromCharCode(...new Uint8Array(signature)));
  const actual = signatureHeader.trim();

  if (expected.length !== actual.length) return false;

  let result = 0;
  for (let i = 0; i < expected.length; i++) {
    result |= expected.charCodeAt(i) ^ actual.charCodeAt(i);
  }
  return result === 0;
}

export { buildCustomer, extractFailureMessage, verifyFedaPayWebhookSignature };
