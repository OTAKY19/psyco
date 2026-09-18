import { HttpError } from "../_shared/errors.ts";
import {
  isUuid,
  normalizeText,
  normalizeTimestamp,
} from "../_shared/validation.ts";
import { jsonResponse } from "../_shared/http.ts";
import {
  countryIso3ToIso2,
  extractFailureMessage,
  fetchFedaPayTransaction,
  mapFedaStatusToInternal,
  normalizeMetadata,
  pickMetadataValue,
  resolveNoRedirectMode,
  sanitizePhoneNumber,
  sendFedaPayNoRedirectPayment,
} from "../_shared/fedapay.ts";
import { fulfillPaymentIntent } from "./db.ts";

export async function attemptNoRedirect(
  providerCode: string,
  paymentToken: string,
  phoneNumber: string,
  countryIso3: string,
): Promise<{ status: string; raw: unknown } | null> {
  const noRedirectMode = resolveNoRedirectMode(providerCode);
  if (!noRedirectMode || !phoneNumber) return null;

  const phoneDigits = sanitizePhoneNumber(phoneNumber);
  const countryIso2 = countryIso3ToIso2(countryIso3).toLowerCase();
  if (!phoneDigits) return null;

  try {
    return await sendFedaPayNoRedirectPayment(noRedirectMode, paymentToken, {
      number: phoneDigits,
      country: countryIso2,
    });
  } catch {
    return null;
  }
}

function decodeSegment(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function extractDeviceIdFromTransaction(
  payload: Record<string, unknown>,
): string {
  const customMetadata = normalizeMetadata(payload.custom_metadata);
  const metadata = normalizeMetadata(payload.metadata);
  return normalizeText(
    pickMetadataValue(
      { ...customMetadata, ...metadata },
      ["device_id", "deviceId", "device"],
    ),
  );
}

export async function handleAppTokenVerify(
  req: Request,
  paymentId: string,
  supabaseClient: Awaited<
    ReturnType<typeof import("../_shared/roles.ts").createRoleClient>
  >,
  applyPaidPaymentFn: (
    paymentId: string,
    deviceId: string,
    rawPayload: Record<string, unknown>,
  ) => Promise<{ processedOnce: boolean; premiumUntil: string; deviceToken: string | null }>,
) {
  if (isUuid(paymentId)) {
    const { data: intent, error } = await supabaseClient
      .from("payment_intents")
      .select("provider_payment_ref, status, fulfillment_status")
      .eq("id", paymentId)
      .maybeSingle();

    if (intent?.status === "completed") {
      return jsonResponse({
        status: "completed",
        premium: intent.fulfillment_status === "fulfilled",
        fulfillment_status: intent.fulfillment_status,
      });
    }

    if (error || !intent?.provider_payment_ref) {
      return jsonResponse({
        status: intent?.status ?? "unknown",
        premium: false,
      });
    }

    paymentId = intent.provider_payment_ref;
  } else {
    const { data: intent } = await supabaseClient
      .from("payment_intents")
      .select("status, fulfillment_status")
      .eq("provider_payment_ref", paymentId)
      .maybeSingle();

    if (intent?.status === "completed") {
      return jsonResponse({
        status: "completed",
        premium: intent.fulfillment_status === "fulfilled",
        fulfillment_status: intent.fulfillment_status,
      });
    }
  }

  const { status, raw, data } = await fetchFedaPayTransaction(paymentId);
  const internalStatus = mapFedaStatusToInternal(status);

  if (internalStatus !== "completed") {
    const message = extractFailureMessage(data) ||
      extractFailureMessage(raw);
    return jsonResponse({
      status: internalStatus,
      premium: false,
      ...(message ? { message } : {}),
    });
  }

  const customMeta = normalizeMetadata(data.custom_metadata);
  const isPartner = customMeta.partner_pack === "true";

  if (isPartner) {
    const paymentIntentId = normalizeText(customMeta.payment_intent_id);
    if (paymentIntentId && isUuid(paymentIntentId)) {
      await supabaseClient
        .from("payment_intents")
        .update({ status: "approved", updated_at: new Date().toISOString() })
        .eq("id", paymentIntentId)
        .in("status", ["created", "pending", "processing"]);
      await fulfillPaymentIntent(paymentIntentId);
      const { data: intent } = await supabaseClient
        .from("payment_intents")
        .select("id, fulfillment_status")
        .eq("id", paymentIntentId)
        .single();
      return jsonResponse({
        status: "completed",
        fulfillment_status: intent?.fulfillment_status ?? "fulfilled",
        premium: false,
      });
    }
    return jsonResponse({ status: "completed", premium: false });
  }

  let deviceId = extractDeviceIdFromTransaction(data);

  if (!deviceId) {
    const paymentIntentId = normalizeText(customMeta.payment_intent_id);
    if (paymentIntentId && isUuid(paymentIntentId)) {
      try {
        const { data: intent, error: intentError } = await supabaseClient
          .from("payment_intents")
          .select("device_id")
          .eq("id", paymentIntentId)
          .maybeSingle();
        if (!intentError && intent?.device_id) {
          deviceId = intent.device_id;
        }
      } catch (lookupError) {
        console.error(
          "[handleAppTokenVerify] Failed to lookup payment_intent for device_id fallback",
          { paymentIntentId, error: lookupError instanceof Error ? lookupError.message : String(lookupError) },
        );
      }
    }
  }

  if (!deviceId) {
    throw new HttpError(
      422,
      "Approved transaction missing device_id metadata",
    );
  }

  const applied = await applyPaidPaymentFn(
    paymentId,
    deviceId,
    raw,
  );

  const paymentIntentId = normalizeText(customMeta.payment_intent_id);
  if (paymentIntentId && isUuid(paymentIntentId)) {
    try {
      await supabaseClient
        .from("payment_intents")
        .update({ status: "approved", updated_at: new Date().toISOString() })
        .eq("id", paymentIntentId)
        .in("status", ["created", "pending", "processing"]);
    } catch (statusUpdateError) {
      console.error("[handleAppTokenVerify] Status update failed before fulfillment:", statusUpdateError);
    }
    try {
      await fulfillPaymentIntent(paymentIntentId);
    } catch (fulfillError) {
      console.error(
        "[handleAppTokenVerify] Non-critical: fulfillPaymentIntent failed after premium grant",
        { paymentIntentId, error: fulfillError instanceof Error ? fulfillError.message : String(fulfillError) },
      );
    }
  }

  return jsonResponse({
    status: "completed",
    premium: true,
    premium_until: applied.premiumUntil,
    processed_once: applied.processedOnce,
    device_token: applied.deviceToken,
  });
}
