import { HttpError } from "../_shared/errors.ts";
import {
  asRecord,
  isUuid,
  normalizePartnerCode,
  normalizeProviderCode,
  normalizeText,
  normalizeTimestamp,
  requireAppToken,
} from "../_shared/validation.ts";
import { withRetry } from "../_shared/retry.ts";
import { jsonResponse } from "../_shared/http.ts";
import {
  buildCustomer,
  createFedaPayTransaction,
  extractFailureMessage,
  fetchFedaPayTransaction,
  getCurrentEnvironment,
  mapFedaStatusToInternal,
  mapInternalStatusToPaymentIntentStatus,
  normalizeCountryIso3,
  normalizeCurrency,
  normalizeMetadata,
  normalizePhoneE164,
  resolveNoRedirectMode,
  sanitizePhoneNumber,
} from "../_shared/fedapay.ts";
import { attemptNoRedirect } from "./fedapay_flow.ts";
import {
  applyPaidPayment,
  createAnonymousPaymentIntent,
  createPaymentIntent,
  findPendingDeviceIntent,
  fulfillPaymentIntent,
  loadActiveAccessGrant,
  loadCatalogProduct,
  loadOwnPaymentIntent,
  normalizeIntentProvider,
  normalizeProductSku,
  requireAuthenticatedPartner,
  requireAuthenticatedStudent,
  resolveSecureCallbackUrl,
  getPaymentsClient,
  redeemActivationCodeForUser,
  updatePaymentIntent,
  validatePartner,
} from "./db.ts";
import {
  computePromoAmount,
  loadActivePromoForSku,
} from "../_shared/pricing.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

export function isPartnerPack(productSku: string): boolean {
  return productSku.startsWith("partner_pack_");
}

function isAccessActive(premiumUntil: string | null): boolean {
  // A null expiry marks a lifetime grant (PsycoTest+ one-time purchase).
  if (premiumUntil == null) return true;
  return new Date(premiumUntil).getTime() > Date.now();
}

export function hasPartnerPaymentMarker(
  body: Record<string, unknown>,
): boolean {
  if (
    normalizeText(body.partner_code ?? body.partnerCode) ||
    normalizeText(body.partner_id ?? body.partnerId)
  ) {
    return true;
  }

  const metadata = asRecord(body.metadata);
  return Boolean(
    normalizeText(metadata.partner_code ?? metadata.partnerCode) ||
      normalizeText(metadata.partner_id ?? metadata.partnerId),
  );
}

export async function createAuthenticatedPayment(
  req: Request,
  body: Record<string, unknown>,
) {
  if (hasPartnerPaymentMarker(body)) {
    throw new HttpError(
      422,
      "partner data is not supported for student premium payments",
    );
  }

  const student = await requireAuthenticatedStudent(req);
  const deviceId = normalizeText(body.device_id ?? body.deviceId);
  await checkRateLimit("create_payment", student.id, 5, 60);
  const productSku = normalizeProductSku(
    body.product_sku ?? body.productSku ?? "premium_lifetime",
  );
  const product = await loadCatalogProduct(productSku);
  const promo = await loadActivePromoForSku(productSku);
  const effectiveAmount = promo
    ? computePromoAmount(product.amount_xof, promo)
    : product.amount_xof;

  const bodyAmount = body.amount != null ? Number(body.amount) : null;
  if (bodyAmount != null && bodyAmount !== effectiveAmount) {
    console.warn(
      `[price-mismatch] productSku=${productSku} bodyAmount=${bodyAmount} catalogAmount=${effectiveAmount}`,
    );
  }

  if (product.kind !== "license_access") {
    throw new HttpError(
      422,
      "Authenticated mobile payment currently supports license_access only",
    );
  }

  const customerBody = asRecord(body.customer);
  const provider = normalizeIntentProvider(body.provider ?? body.correspondent);

  const countryIso3 = normalizeCountryIso3(body.country);
  const phoneE164 = normalizePhoneE164(
    customerBody.phone ?? body.phone,
    countryIso3,
  );

  const metadata = normalizeMetadata(body.metadata);
  const rawNonce = body.client_nonce ?? body.idempotency_key;
  const clientNonce = rawNonce ? String(rawNonce) : undefined;
  if (clientNonce && !isUuid(clientNonce)) {
    throw new HttpError(400, "client_nonce must be a valid UUID");
  }
  const paymentIntent = await createPaymentIntent({
    client_nonce: clientNonce,
    auth_user_id: student.id,
    partner_id: null,
    product_id: product.id,
    provider: provider || null,
    phone_e164: phoneE164 || null,
    customer_email: normalizeText(customerBody.email) || null,
    customer_first_name: normalizeText(customerBody.firstName) ||
      normalizeText(customerBody.firstname) ||
      null,
    customer_last_name: normalizeText(customerBody.lastName) ||
      normalizeText(customerBody.lastname) ||
      null,
    amount_xof: effectiveAmount,
    currency: product.currency,
    promotion_id: promo?.id ?? null,
    environment: getCurrentEnvironment(),
    status: "created",
    raw_metadata: {
      ...metadata,
      product_sku: product.sku,
      requested_amount: body.amount ?? null,
    },
  });

  if (paymentIntent.provider_payment_ref) {
    return jsonResponse({
      ok: true,
      transactionId: paymentIntent.provider_payment_ref,
      status: paymentIntent.status,
      paymentIntentId: paymentIntent.id,
      checkoutUrl: null,
    });
  }

  const customer = buildCustomer(customerBody, countryIso3);
  const providerCode = provider.toUpperCase();
  const noRedirectMode = resolveNoRedirectMode(providerCode);
  const canUseNoRedirect = Boolean(noRedirectMode && phoneE164);
  const callbackUrl = normalizeText(body.callback_url) ||
    await resolveSecureCallbackUrl();
  const customMetadata: Record<string, string> = {
    ...metadata,
    payment_intent_id: paymentIntent.id,
    product_sku: product.sku,
    device_id: deviceId || "",
    app: "PsycoTest+",
    premium_duration_days: product.premium_duration_days != null
      ? String(product.premium_duration_days)
      : "lifetime",
  };

  try {
    const payment = await createFedaPayTransaction({
      amount: effectiveAmount,
      currency: product.currency,
      description: normalizeText(body.description) || product.name,
      callbackUrl: callbackUrl || undefined,
      mode: canUseNoRedirect ? `${noRedirectMode}_open` : undefined,
      customer,
      customMetadata,
    });

    await updatePaymentIntent(paymentIntent.id, {
      provider_payment_ref: String(payment.transactionId),
      provider_payload: payment.raw,
      status: mapInternalStatusToPaymentIntentStatus(
        mapFedaStatusToInternal(payment.status),
      ),
    });

    const noRedirectResult = await attemptNoRedirect(
      providerCode,
      payment.token,
      phoneE164,
      countryIso3,
    );

    if (noRedirectResult) {
      await updatePaymentIntent(paymentIntent.id, {
        provider_payload: { ...payment.raw, no_redirect: noRedirectResult.raw },
        status: mapInternalStatusToPaymentIntentStatus(
          mapFedaStatusToInternal(noRedirectResult.status || payment.status),
        ),
      });

      return jsonResponse({
        paymentId: paymentIntent.id,
        providerPaymentId: String(payment.transactionId),
        transactionReference: payment.reference,
        status: noRedirectResult.status || payment.status || "pending",
        amount: effectiveAmount,
        currency: product.currency,
        gateway: "fedapay",
        flow: "no_redirect",
        noRedirect: true,
        provider,
        premiumDurationDays: product.premium_duration_days,
        actionRequired: true,
        actionHint:
          "Confirmez la demande de paiement sur votre téléphone Mobile Money.",
      });
    }

    return jsonResponse({
      paymentId: paymentIntent.id,
      providerPaymentId: String(payment.transactionId),
      transactionReference: payment.reference,
      status: payment.status,
      amount: effectiveAmount,
      currency: product.currency,
      gateway: "fedapay",
      checkoutUrl: payment.checkoutUrl,
      successUrl: callbackUrl || undefined,
      cancelUrl: callbackUrl || undefined,
      premiumDurationDays: product.premium_duration_days,
      actionRequired: true,
      actionHint: canUseNoRedirect
        ? "Le paiement sans redirection n'est pas disponible pour le moment. Finalisez le paiement sur la page FedaPay puis revenez dans l'application."
        : "Finalisez le paiement sur la page FedaPay puis revenez dans l'application.",
    });
  } catch (error) {
    await updatePaymentIntent(paymentIntent.id, {
      status: "failed",
      provider_payload: {
        error: error instanceof Error ? error.message : "Unknown payment error",
      },
    }).catch((e) => {
      console.error("[payments] Failed to update payment intent to failed status:", e);
    });
    throw error;
  }
}

export async function verifyAuthenticatedPayment(
  req: Request,
  paymentId: string,
) {
  if (!isUuid(paymentId)) {
    throw new HttpError(404, "Payment intent not found");
  }

  const authUser = await requireAuthenticatedStudent(req);
  const intent = await loadOwnPaymentIntent(paymentId, authUser.id);

  if (intent.status === "completed") {
    if (intent.fulfillment_status !== "fulfilled") {
      await fulfillPaymentIntent(paymentId);
    }
    const grant = await loadActiveAccessGrant(authUser.id, paymentId);
    const premiumUntil = normalizeTimestamp(grant?.ends_at);
    return jsonResponse({
      status: "completed",
      premium: grant != null && isAccessActive(premiumUntil),
      premium_until: premiumUntil,
      fulfillment_status: intent.fulfillment_status,
    });
  }

  if (!intent.provider_payment_ref) {
    return jsonResponse({
      status: intent.status,
      premium: false,
    });
  }

  const { status, raw, data } = await fetchFedaPayTransaction(
    intent.provider_payment_ref,
  );
  const internalStatus = mapFedaStatusToInternal(status);

  const client = await getPaymentsClient();
    await client.rpc("update_payment_intent_status_if", {
    p_payment_intent_id: paymentId,
    p_expected_status: intent.status,
    p_new_status: mapInternalStatusToPaymentIntentStatus(internalStatus),
    p_payload: raw,
  });

  if (internalStatus !== "completed") {
    const message = extractFailureMessage(data) || extractFailureMessage(raw);
    return jsonResponse({
      status: internalStatus,
      premium: false,
      ...(message ? { message } : {}),
    });
  }

  const fulfillment = intent.fulfillment_status === "fulfilled"
    ? null
    : await fulfillPaymentIntent(paymentId);
  const grant = await loadActiveAccessGrant(authUser.id, paymentId);
  const premiumUntil = normalizeTimestamp(
    fulfillment?.premium_until ?? grant?.ends_at,
  );
  const hasAccess = fulfillment != null || grant != null;

  return jsonResponse({
    status: "completed",
    premium: hasAccess && isAccessActive(premiumUntil),
    premium_until: premiumUntil,
    fulfillment_status: fulfillment?.fulfillment_status ??
      intent.fulfillment_status,
  });
}

export async function createPartnerPackPayment(
  req: Request,
  body: Record<string, unknown>,
) {
  const { userId, partnerId, partnerCode, userEmail } =
    await requireAuthenticatedPartner(req);
  await checkRateLimit("create_payment", userId, 5, 60);
  const productSku = normalizeProductSku(
    body.product_sku ?? body.productSku ?? "",
  );
  const product = await loadCatalogProduct(productSku);
  if (product.kind !== "activation_pack") {
    throw new HttpError(
      422,
      "Partner payments require activation_pack products",
    );
  }
  const promo = await loadActivePromoForSku(productSku);
  const effectiveAmount = promo
    ? computePromoAmount(product.amount_xof, promo)
    : product.amount_xof;

  const bodyAmount = body.amount != null ? Number(body.amount) : null;
  if (bodyAmount != null && bodyAmount !== effectiveAmount) {
    console.warn(
      `[price-mismatch] productSku=${productSku} bodyAmount=${bodyAmount} catalogAmount=${effectiveAmount} partnerId=${partnerId}`,
    );
  }

  const provider = normalizeIntentProvider(body.provider ?? body.correspondent);

  const countryIso3 = normalizeCountryIso3(body.country);
  const phoneE164 = normalizePhoneE164(body.phone, countryIso3);

  const quantity = product.activation_code_quantity ?? 1;

  const metadata = normalizeMetadata(body.metadata);
  const rawNonce = body.client_nonce ?? body.idempotency_key;
  const clientNonce = rawNonce ? String(rawNonce) : undefined;
  if (clientNonce && !isUuid(clientNonce)) {
    throw new HttpError(400, "client_nonce must be a valid UUID");
  }
  const paymentIntent = await createPaymentIntent({
    client_nonce: clientNonce,
    auth_user_id: userId,
    partner_id: partnerId,
    product_id: product.id,
    provider: provider || null,
    phone_e164: phoneE164 || null,
    amount_xof: effectiveAmount,
    currency: product.currency,
    promotion_id: promo?.id ?? null,
    environment: getCurrentEnvironment(),
    status: "created",
    raw_metadata: {
      ...metadata,
      product_sku: product.sku,
      partner_id: partnerId,
      partner_code: partnerCode,
      partner_pack: true,
      quantity: quantity,
      premium_duration_days: product.premium_duration_days,
    },
  });

  if (paymentIntent.provider_payment_ref) {
    return jsonResponse({
      ok: true,
      transactionId: paymentIntent.provider_payment_ref,
      status: paymentIntent.status,
      paymentIntentId: paymentIntent.id,
      checkoutUrl: null,
    });
  }

  const providerCode = provider.toUpperCase();
  const noRedirectMode = resolveNoRedirectMode(providerCode);
  const canUseNoRedirect = Boolean(noRedirectMode && phoneE164);
  const callbackUrl = normalizeText(body.callback_url) ||
    await resolveSecureCallbackUrl();
  const customMetadata: Record<string, string> = {
    ...metadata,
    payment_intent_id: paymentIntent.id,
    product_sku: product.sku,
    app: "PsycoTest+",
    partner_code: partnerCode,
    premium_duration_days: product.premium_duration_days != null
      ? String(product.premium_duration_days)
      : "lifetime",
  };

  const customer = buildCustomer({ email: userEmail }, countryIso3);

  try {
    const payment = await createFedaPayTransaction({
      amount: effectiveAmount,
      currency: product.currency,
      description: `Pack partenaire - ${product.name}`,
      callbackUrl,
      mode: canUseNoRedirect ? `${noRedirectMode}_open` : undefined,
      customer,
      customMetadata,
    });

    await updatePaymentIntent(paymentIntent.id, {
      provider_payment_ref: String(payment.transactionId),
      status: "pending",
      provider_payload: payment,
    });

    if (canUseNoRedirect && phoneE164 && payment.checkoutUrl) {
      return jsonResponse({
        paymentId: String(payment.transactionId),
        transactionReference: payment.reference,
        status: payment.status,
        amount: effectiveAmount,
        currency: product.currency,
        checkoutUrl: payment.checkoutUrl,
        successUrl: callbackUrl,
        cancelUrl: callbackUrl,
        gateway: "fedapay",
      });
    }

    return jsonResponse({
      paymentId: String(payment.transactionId),
      transactionReference: payment.reference,
      status: payment.status,
      amount: effectiveAmount,
      currency: product.currency,
      gateway: "fedapay",
      checkoutUrl: payment.checkoutUrl,
      successUrl: callbackUrl,
      cancelUrl: callbackUrl,
      partnerCode: partnerCode,
      actionRequired: true,
      actionHint:
        "Finalisez le paiement sur la page FedaPay puis revenez dans l'application.",
    });
  } catch (error) {
    await updatePaymentIntent(paymentIntent.id, {
      status: "failed",
      provider_payload: error instanceof Error ? { error: error.message } : {},
    });
    throw error;
  }
}

export async function createAnonymousPayment(
  req: Request,
  body: Record<string, unknown>,
) {
  const PAYMENT_APP_TOKEN = Deno.env.get("PAYMENT_APP_TOKEN") ?? "";
  const PRICE_XOF = Number(Deno.env.get("PRICE_XOF") ?? "3000");

  requireAppToken(req, PAYMENT_APP_TOKEN);

  const deviceId = normalizeText(body.device_id);
  const partnerCodeRaw = normalizePartnerCode(body.partner_code);
  const providerCode = normalizeProviderCode(
    body.provider ?? body.correspondent,
  );

  if (!deviceId) {
    return jsonResponse({ error: "device_id required" }, 400);
  }

  await checkRateLimit("create_payment", deviceId, 5, 60);

  const partnerCheck = await validatePartner(partnerCodeRaw || undefined);
  const resolvedPartnerCode = partnerCheck.valid && partnerCodeRaw
    ? (partnerCheck.code ?? partnerCodeRaw)
    : null;

  const premiumProduct = await loadCatalogProduct("premium_lifetime");
  const promo = await loadActivePromoForSku("premium_lifetime");
  const effectiveAmount = promo
    ? computePromoAmount(premiumProduct.amount_xof ?? PRICE_XOF, promo)
    : premiumProduct.amount_xof ?? PRICE_XOF;

  const amount = Math.floor(effectiveAmount);
  const currency = normalizeCurrency(body.currency);

  const existingIntent = await findPendingDeviceIntent(deviceId);
  if (existingIntent?.provider_payment_ref) {
    return jsonResponse({
      paymentId: existingIntent.provider_payment_ref,
      status: existingIntent.status,
      amount,
      currency,
      checkoutUrl: null,
      gateway: "fedapay",
      callbackUrl: await resolveSecureCallbackUrl(),
    });
  }

  const anonymousIntent = await createAnonymousPaymentIntent(
    deviceId,
    providerCode,
    amount,
    currency,
    promo?.id || undefined,
  );
  const countryIso3 = normalizeCountryIso3(body.country);
  const noRedirectMode = resolveNoRedirectMode(providerCode);

  const durationDays = premiumProduct?.premium_duration_days ?? null;

  const metadata = normalizeMetadata(body.metadata);
  const customMetadata: Record<string, string> = {
    ...metadata,
    payment_intent_id: anonymousIntent.id,
    device_id: deviceId,
    app: "PsycoTest+",
    premium_duration_days: durationDays != null
      ? String(durationDays)
      : "lifetime",
  };

  if (resolvedPartnerCode) {
    customMetadata.partner_code = resolvedPartnerCode;
  } else {
    delete customMetadata.partner_code;
    delete customMetadata.partnerCode;
  }

  const customerBody = asRecord(body.customer);
  if (!customerBody.email && !customerBody.phone && !customerBody.name) {
    console.warn("[payments] No customer data provided for transaction");
  }
  const customer = buildCustomer(customerBody, countryIso3);
  const phoneNumber = sanitizePhoneNumber(customerBody.phone);
  const canUseNoRedirect = Boolean(noRedirectMode && phoneNumber);

  const callbackUrl = normalizeText(body.callback_url) ||
    await resolveSecureCallbackUrl();

  const payment = await createFedaPayTransaction({
    amount,
    currency,
    description: normalizeText(body.description) || "PsycoTest+ Premium",
    callbackUrl: callbackUrl || undefined,
    mode: canUseNoRedirect ? `${noRedirectMode}_open` : undefined,
    customer,
    customMetadata,
  });

  // Backfill the FedaPay transaction id onto the intent. This write MUST
  // succeed: the webhook matches intents by provider_payment_ref, so a missing
  // ref means a successfully-charged payment can never be fulfilled. We retry
  // with backoff instead of letting a transient DB error lose the payment.
  const client = await getPaymentsClient();
  await withRetry(
    async () => {
      const { error: updateError } = await client
        .from("payment_intents")
        .update({
          provider_payment_ref: String(payment.transactionId),
          provider_payload: payment.raw ?? {},
          updated_at: new Date().toISOString(),
        })
        .eq("id", anonymousIntent.id);
      if (updateError) throw updateError;
    },
    {
      maxAttempts: 5,
      baseDelayMs: 500,
      logger: {
        warn: (...args: unknown[]) => console.warn("[payments]", ...args),
        error: (...args: unknown[]) => console.error("[payments]", ...args),
      },
      label: "backfill payment_intent ref",
    },
  );

  const noRedirectResult = await attemptNoRedirect(
    providerCode,
    payment.token,
    phoneNumber,
    countryIso3,
  );

  if (noRedirectResult) {
    return jsonResponse({
      paymentId: String(payment.transactionId),
      transactionReference: payment.reference,
      status: noRedirectResult.status || payment.status || "pending",
      amount,
      currency,
      gateway: "fedapay",
      flow: "no_redirect",
      noRedirect: true,
      provider: providerCode,
      partnerCodeValid: partnerCheck.valid,
      ...(resolvedPartnerCode ? { partnerCode: resolvedPartnerCode } : {}),
      ...(partnerCheck.name ? { partnerName: partnerCheck.name } : {}),
      premiumDurationDays: durationDays,
      actionRequired: true,
      actionHint:
        "Confirmez la demande de paiement sur votre téléphone Mobile Money.",
    });
  }

  return jsonResponse({
    paymentId: String(payment.transactionId),
    transactionReference: payment.reference,
    status: payment.status,
    amount,
    currency,
    gateway: "fedapay",
    checkoutUrl: payment.checkoutUrl,
    successUrl: callbackUrl || undefined,
    cancelUrl: callbackUrl || undefined,
    partnerCodeValid: partnerCheck.valid,
    ...(resolvedPartnerCode ? { partnerCode: resolvedPartnerCode } : {}),
    ...(partnerCheck.name ? { partnerName: partnerCheck.name } : {}),
    premiumDurationDays: durationDays,
    actionRequired: true,
    actionHint: canUseNoRedirect
      ? "Le paiement sans redirection n'est pas disponible pour le moment. Finalisez le paiement sur la page FedaPay puis revenez dans l'application."
      : "Finalisez le paiement sur la page FedaPay puis revenez dans l'application.",
  });
}

export async function redeemActivationCode(
  req: Request,
  body: Record<string, unknown>,
) {
  const student = await requireAuthenticatedStudent(req);
  const code = normalizeText(body.code ?? body.activation_code);
  if (!code) throw new HttpError(400, "activation code required");

  await checkRateLimit("redeem_activation_code", student.id, 10, 60);

  const result = await redeemActivationCodeForUser(student.id, code);
  if (!result) {
    throw new HttpError(400, "Code invalide ou deja utilise");
  }

  return jsonResponse({
    ok: true,
    activationCodeId: result.activation_code_id ?? null,
    productSku: result.product_sku ?? null,
    status: result.status ?? "granted",
    premium: true,
    premium_until: normalizeTimestamp(result.premium_until) ?? null,
  });
}
