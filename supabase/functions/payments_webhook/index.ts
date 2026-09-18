import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { HttpError } from "../_shared/errors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import {
  asRecord,
  normalizeScalarText,
  normalizeText,
} from "../_shared/validation.ts";
import { handleOptions, jsonError, jsonResponse } from "../_shared/http.ts";
import {
  DEFAULT_APP_SCHEME,
  getAppScheme,
  refreshFedaPayConfig,
  verifyFedaPayWebhookSignature,
} from "../_shared/fedapay.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  "";
const FEDAPAY_WEBHOOK_TOKEN = Deno.env.get("FEDAPAY_WEBHOOK_TOKEN") ?? "";
const FEDAPAY_WEBHOOK_SECRET = Deno.env.get("FEDAPAY_WEBHOOK_SECRET") ?? "";
const FEDAPAY_SANDBOX_WEBHOOK_SECRET =
  Deno.env.get("FEDAPAY_SANDBOX_WEBHOOK_SECRET") ?? "";
const FEDAPAY_SANDBOX_WEBHOOK_TOKEN =
  Deno.env.get("FEDAPAY_SANDBOX_WEBHOOK_TOKEN") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function requireEnv() {
  const missing: string[] = [];
  if (!SUPABASE_URL) missing.push("SUPABASE_URL");
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    missing.push("SUPABASE_SERVICE_ROLE_KEY");
  }
  if (
    !FEDAPAY_WEBHOOK_TOKEN && !FEDAPAY_WEBHOOK_SECRET &&
    !FEDAPAY_SANDBOX_WEBHOOK_SECRET && !FEDAPAY_SANDBOX_WEBHOOK_TOKEN
  ) {
    missing.push(
      "FEDAPAY_WEBHOOK_TOKEN, FEDAPAY_WEBHOOK_SECRET, FEDAPAY_SANDBOX_WEBHOOK_SECRET, or FEDAPAY_SANDBOX_WEBHOOK_TOKEN",
    );
  }
  if (missing.length) {
    throw new Error(`Missing env: ${missing.join(", ")}`);
  }
}

async function requireWebhookToken(
  request: Request,
): Promise<{ environment: "sandbox" | "live" }> {
  const headerToken = request.headers.get("x-webhook-token");
  if (headerToken) {
    if (headerToken === FEDAPAY_WEBHOOK_TOKEN) return { environment: "live" };
    if (
      FEDAPAY_SANDBOX_WEBHOOK_TOKEN &&
      headerToken === FEDAPAY_SANDBOX_WEBHOOK_TOKEN
    ) return { environment: "sandbox" };
  }

  const body = await request.clone().text();
  const signature = request.headers.get("x-fedapay-signature");

  if (signature) {
    const secretsToTry: { secret: string; environment: "sandbox" | "live" }[] =
      [
        { secret: FEDAPAY_WEBHOOK_SECRET, environment: "live" },
        { secret: FEDAPAY_SANDBOX_WEBHOOK_SECRET, environment: "sandbox" },
      ];
    for (const { secret, environment } of secretsToTry) {
      if (!secret) continue;
      const isValid = await verifyFedaPayWebhookSignature(
        body,
        signature,
        secret,
      );
      if (isValid) return { environment };
    }
  }

  const queryToken = new URL(request.url).searchParams.get("token");
  if (queryToken) {
    if (queryToken === FEDAPAY_WEBHOOK_TOKEN) {
      console.warn(
        "[DEPRECATED] Webhook token in URL query parameter. Configure x-webhook-token header instead.",
      );
      return { environment: "live" };
    }
    if (
      FEDAPAY_SANDBOX_WEBHOOK_TOKEN &&
      queryToken === FEDAPAY_SANDBOX_WEBHOOK_TOKEN
    ) {
      console.warn(
        "[DEPRECATED] Webhook token in URL query parameter. Configure x-webhook-token header instead.",
      );
      return { environment: "sandbox" };
    }
  }

  throw new HttpError(401, "Unauthorized webhook");
}

function extractWebhookEntity(
  body: Record<string, unknown>,
): Record<string, unknown> {
  return asRecord(body.entity ?? body.data ?? body.transaction);
}

function extractWebhookTransactionId(body: Record<string, unknown>): string {
  const entity = extractWebhookEntity(body);
  return normalizeScalarText(
    body.object_id ??
      body.id ??
      body.transaction_id ??
      entity.id ??
      entity.object_id ??
      entity.transaction_id,
  );
}

function extractWebhookStatus(body: Record<string, unknown>): string {
  const entity = extractWebhookEntity(body);
  const rawStatus = normalizeScalarText(
    body.status ??
      body.name ??
      body.event ??
      entity.status ??
      entity.event ??
      entity.name,
  ).toLowerCase();

  if (rawStatus.includes("approved")) return "completed";
  if (rawStatus.includes("transferred")) return "completed";
  if (rawStatus.includes("pending")) return "pending";
  if (rawStatus.includes("created")) return "pending";
  if (rawStatus.includes("declined")) return "failed";
  if (rawStatus.includes("canceled")) return "failed";
  if (rawStatus.includes("deleted")) return "failed";
  if (rawStatus.includes("refunded")) return "failed";
  if (rawStatus.includes("expired")) return "failed";
  return rawStatus || "pending";
}

function extractProviderEventId(
  transactionId: string,
  body: Record<string, unknown>,
): string {
  const suffix = normalizeScalarText(
    body.event_id ?? body.id ?? body.created_at ?? body.triggered_at,
  );
  const status = extractWebhookStatus(body);
  return `fedapay:${transactionId}:${status}:${suffix || "event"}`;
}

async function findPaymentIntentByProviderReference(
  providerPaymentRef: string,
) {
  const { data, error } = await supabase
    .from("payment_intents")
    .select("id, status, fulfillment_status, amount_xof, environment")
    .eq("provider_payment_ref", providerPaymentRef)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "Failed payment intent lookup");
  }

  return data;
}

async function recordWebhookEvent(
  paymentIntentId: string,
  providerEventId: string,
  eventType: string,
  payload: Record<string, unknown>,
) {
  const { error } = await supabase
    .from("payment_provider_events")
    .insert({
      event_type: eventType,
      payment_intent_id: paymentIntentId,
      payload,
      provider_event_id: providerEventId,
    });

  if (error && error.code !== "23505") {
    throw new HttpError(500, "Failed payment event insert");
  }
}

async function updatePaymentIntentStatus(
  paymentIntentId: string,
  expectedStatus: string,
  newStatus: string,
  payload: Record<string, unknown>,
): Promise<boolean> {
  const { data, error } = await supabase.rpc(
    "update_payment_intent_status_if",
    {
      p_payment_intent_id: paymentIntentId,
      p_expected_status: expectedStatus,
      p_new_status: newStatus,
      p_payload: payload,
    },
  );

  if (error) {
    throw new HttpError(500, "Failed payment intent update");
  }

  return data === true;
}

async function fulfillPaymentIntent(paymentIntentId: string) {
  const { error } = await supabase.rpc("fulfill_payment_intent", {
    p_payment_intent_id: paymentIntentId,
  });

  if (error) {
    throw new HttpError(500, "Failed payment fulfillment");
  }
}

function buildRedirectResponse(
  status: string,
  transactionId: string,
  appScheme: string = DEFAULT_APP_SCHEME,
): Response {
  const appLink = `${appScheme}://app/payment/callback?status=${
    encodeURIComponent(status)
  }&transaction_id=${encodeURIComponent(transactionId)}`;

  const html = `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redirection...</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; color: #333; }
    .card { background: white; border-radius: 12px; padding: 32px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.1); max-width: 360px; }
    .status-icon { font-size: 48px; margin-bottom: 16px; }
    h1 { font-size: 20px; margin: 0 0 8px; }
    p { color: #666; margin: 0 0 24px; font-size: 14px; }
    a { color: #1a73e8; text-decoration: none; font-weight: 500; }
  </style>
</head>
<body>
  <div class="card">
    <div class="status-icon">${
    status === "success" ? "✅" : status === "failed" ? "❌" : "⏳"
  }</div>
    <h1>${
    status === "success"
      ? "Paiement réussi !"
      : status === "failed"
      ? "Paiement échoué"
      : "Paiement en cours..."
  }</h1>
    <p>${
    status === "success"
      ? "Votre paiement a été traité avec succès. Vous allez être redirigé..."
      : status === "failed"
      ? "Le paiement n'a pas pu aboutir. Veuillez réessayer."
      : "Votre paiement est en cours de traitement. Vous allez être redirigé..."
  }</p>
    <a href="${appLink}">Ouvrir l'application</a>
  </div>
  <script>setTimeout(function(){ window.location.href = "${appLink}"; }, 2000);</script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

function extractWebhookAmount(
  payload: Record<string, unknown>,
): number | null {
  const entity = extractWebhookEntity(payload);
  const raw = entity.amount ?? entity.amount_xof ?? payload.amount;
  if (raw === undefined || raw === null) return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

function parseJsonBody(raw: string): Record<string, unknown> | null {
  if (!raw || !raw.trim()) return null;
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
    return null;
  } catch {
    return null;
  }
}

async function processWebhookPayload(
  transactionId: string,
  status: string,
  payload: Record<string, unknown>,
  environment: "sandbox" | "live",
) {
  const intent = await findPaymentIntentByProviderReference(transactionId);
  if (!intent?.id) {
    throw new Error(
      `No payment_intent found for provider_payment_ref: ${transactionId}`,
    );
  }

  if (intent.environment && intent.environment !== environment) {
    throw new HttpError(
      403,
      `Webhook environment mismatch: webhook=${environment}, intent=${intent.environment}`,
    );
  }

  const webhookAmount = extractWebhookAmount(payload);
  if (
    intent.amount_xof && webhookAmount !== null &&
    intent.amount_xof !== webhookAmount
  ) {
    throw new HttpError(
      422,
      `Amount mismatch for ${transactionId}: intent=${intent.amount_xof}, webhook=${webhookAmount}`,
    );
  }

  const providerEventId = extractProviderEventId(transactionId, payload);
  await recordWebhookEvent(intent.id, providerEventId, status, payload);

  const wasUpdated = await updatePaymentIntentStatus(
    intent.id,
    intent.status,
    status,
    payload,
  );

  if (status === "completed" && wasUpdated) {
    await fulfillPaymentIntent(intent.id);
  }
}

Deno.serve(async (req) => {
  try {
    const maybeOptions = handleOptions(req);
    if (maybeOptions) return maybeOptions;

    requireEnv();
    const config = await refreshFedaPayConfig(supabase);

    if (req.method === "GET") {
      const url = new URL(req.url);
      const transactionId = normalizeText(
        url.searchParams.get("transaction_id") ??
          url.searchParams.get("id") ??
          "",
      );
      const rawStatus = normalizeText(
        url.searchParams.get("status") ?? "",
      ).toLowerCase();
      const displayStatus = rawStatus.includes("approved") ||
          rawStatus.includes("success") ||
          rawStatus.includes("completed")
        ? "success"
        : rawStatus.includes("cancel") || rawStatus.includes("failed")
        ? "failed"
        : "pending";

      const appScheme = await getAppScheme(supabase);
      return buildRedirectResponse(displayStatus, transactionId, appScheme);
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const authResult = await requireWebhookToken(req);
    const webhookEnvironment = authResult.environment;

    if (config.environment !== webhookEnvironment) {
      console.warn(
        `[webhook] Rejecting ${webhookEnvironment} webhook (current mode: ${config.environment})`,
      );
      return jsonResponse({
        ok: false,
        processed: false,
        error:
          `Webhook environment mismatch: webhook=${webhookEnvironment}, current=${config.environment}`,
      }, 403);
    }

    const rawBody = await req.text();
    const body = parseJsonBody(rawBody);
    if (!body) {
      return jsonResponse({
        ok: false,
        processed: false,
        error: "Invalid or empty JSON body",
      }, 400);
    }

    const transactionId = extractWebhookTransactionId(body);
    const status = extractWebhookStatus(body);

    if (!transactionId) {
      return jsonResponse({
        ok: false,
        processed: false,
        error: "Unable to extract transaction ID from payload",
      }, 422);
    }

    const clientIp =
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
        req.headers.get("x-real-ip") ?? "unknown";
    await checkRateLimit("webhook", clientIp, 20, 60);

    await processWebhookPayload(
      transactionId,
      status,
      body,
      webhookEnvironment,
    );

    return jsonResponse({
      ok: true,
      paymentId: transactionId,
      processed: true,
      status,
    });
  } catch (err) {
    return jsonError(err);
  }
});
