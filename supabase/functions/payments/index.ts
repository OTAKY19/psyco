import {
  asRecord,
  extractBearerToken,
  extractFunctionPath,
  isUuid,
  normalizeText,
  requireAppToken,
} from "../_shared/validation.ts";
import { handleOptions, jsonError, jsonResponse } from "../_shared/http.ts";
import { parseJsonBody } from "../_shared/body_limit.ts";
import { refreshFedaPayConfig } from "../_shared/fedapay.ts";
import { applyPaidPayment, getPaymentsClient } from "./db.ts";
import { handleAppTokenVerify } from "./fedapay_flow.ts";
import {
  createAnonymousPayment,
  createAuthenticatedPayment,
  createPartnerPackPayment,
  hasPartnerPaymentMarker,
  redeemActivationCode,
  verifyAuthenticatedPayment,
} from "./handlers.ts";

const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const FEDAPAY_CALLBACK_URL = Deno.env.get("FEDAPAY_CALLBACK_URL") ?? "";
const PAYMENT_APP_TOKEN = Deno.env.get("PAYMENT_APP_TOKEN") ?? "";

const PRICE_XOF = Number(Deno.env.get("PRICE_XOF") ?? "3000");
const PREMIUM_DURATION_DAYS = Number(
  Deno.env.get("PREMIUM_DURATION_DAYS") ?? "36500",
);

function requireEnv() {
  const missing: string[] = [];
  if (!Deno.env.get("SUPABASE_URL")) missing.push("SUPABASE_URL");
  // JWT_SECRET only needed when CUSTOM_ROLES_ENABLED=true (Supabase Pro).
  // roles.ts falls back to service_role on lower plans, so do not fail here.
  if (
    !Deno.env.get("FEDAPAY_API_TOKEN") &&
    !Deno.env.get("CLE_SECRETE") &&
    !Deno.env.get("FEDAPAY_SANDBOX_TOKEN")
  ) {
    missing.push("FEDAPAY_API_TOKEN or CLE_SECRETE or FEDAPAY_SANDBOX_TOKEN");
  }
  if (!PAYMENT_APP_TOKEN) missing.push("PAYMENT_APP_TOKEN");
  if (missing.length) throw new Error(`Missing env: ${missing.join(", ")}`);
  const fedapayUrl = Deno.env.get("FEDAPAY_API_URL");
  if (fedapayUrl && !/^https?:\/\//i.test(fedapayUrl)) {
    throw new Error("Invalid env FEDAPAY_API_URL: expected an absolute URL");
  }
  const sandboxUrl = Deno.env.get("FEDAPAY_SANDBOX_API_URL");
  if (sandboxUrl && !/^https?:\/\//i.test(sandboxUrl)) {
    throw new Error(
      "Invalid env FEDAPAY_SANDBOX_API_URL: expected an absolute URL",
    );
  }
  if (FEDAPAY_CALLBACK_URL && !/^https?:\/\//i.test(FEDAPAY_CALLBACK_URL)) {
    throw new Error(
      "Invalid env FEDAPAY_CALLBACK_URL: expected an absolute URL",
    );
  }
  if (!Number.isFinite(PREMIUM_DURATION_DAYS) || PREMIUM_DURATION_DAYS <= 0) {
    throw new Error(
      "Invalid env PREMIUM_DURATION_DAYS: expected a positive number",
    );
  }
}

Deno.serve(async (req) => {
  try {
    const maybeOptions = handleOptions(req);
    if (maybeOptions) return maybeOptions;

    requireEnv();
    const pClient = await getPaymentsClient();
    await refreshFedaPayConfig(pClient);

    const url = new URL(req.url);
    const path = extractFunctionPath(url.pathname, "payments").replace(
      /\/+$/,
      "",
    );

    if (req.method === "POST" && !path) {
      const body = asRecord(await parseJsonBody(req));
      const productSku = normalizeText(body.product_sku ?? body.productSku);
      const bearerToken = extractBearerToken(req.headers.get("authorization"));

      if (productSku && bearerToken) {
        if (hasPartnerPaymentMarker(body)) {
          return await createPartnerPackPayment(req, body);
        }
        return await createAuthenticatedPayment(req, body);
      }

      return await createAnonymousPayment(req, body);
    }

    if (req.method === "POST" && path === "redeem") {
      const body = asRecord(await parseJsonBody(req));
      return await redeemActivationCode(req, body);
    }

    if (req.method === "GET" && path) {
      const parts = path.split("/").filter((segment) => segment.length > 0);
      const paymentId = normalizeText(decodeURIComponent(parts[0] ?? ""));
      const maybeVerify = parts[1] ?? "";
      const extraSegment = parts.length > 2 ? parts[2] : "";

      if (!paymentId || maybeVerify !== "verify" || extraSegment) {
        return jsonResponse({ error: "Not found" }, 404);
      }

      const bearerToken = extractBearerToken(req.headers.get("authorization"));
      if (bearerToken && isUuid(paymentId)) {
        return await verifyAuthenticatedPayment(req, paymentId);
      }

      requireAppToken(req, PAYMENT_APP_TOKEN);

      return await handleAppTokenVerify(
        req,
        paymentId,
        pClient,
        applyPaidPayment,
      );
    }

    if (req.method === "POST" || req.method === "GET") {
      return jsonResponse({ error: "Not found" }, 404);
    }

    return jsonResponse({ error: "Method not allowed" }, 405);
  } catch (err) {
    return jsonError(err);
  }
});
