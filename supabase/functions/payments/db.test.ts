import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");
Deno.env.set(
  "FEDAPAY_CALLBACK_URL",
  "https://example.com/fn/v1/payments/webhook?token=secret",
);
Deno.env.set("FEDAPAY_PAYMENT_INTENTS_CALLBACK_URL", "");

Deno.test("normalizeProductSku", async () => {
  const { normalizeProductSku } = await import("./db.ts");

  assertEquals(normalizeProductSku(null), "");
  assertEquals(normalizeProductSku(undefined), "");
  assertEquals(normalizeProductSku(123), "");
  assertEquals(normalizeProductSku({}), "");
  assertEquals(normalizeProductSku(""), "");

  assertEquals(normalizeProductSku("Premium_lifetime"), "premium_lifetime");
  assertEquals(normalizeProductSku("PREMIUM 90D!"), "premium90d");
  assertEquals(normalizeProductSku("PREMIUM-90D_"), "premium-90d_");
  assertEquals(normalizeProductSku("ABC-123_xyz"), "abc-123_xyz");
  assertEquals(normalizeProductSku("partner_pack_50"), "partner_pack_50");

  assertEquals(normalizeProductSku("  premium_lifetime  "), "premium_lifetime");
  assertEquals(normalizeProductSku("   "), "");
});

Deno.test("normalizeIntentProvider", async () => {
  const { normalizeIntentProvider } = await import("./db.ts");

  assertEquals(normalizeIntentProvider(null), "");
  assertEquals(normalizeIntentProvider(undefined), "");
  assertEquals(normalizeIntentProvider(""), "");
  assertEquals(normalizeIntentProvider(0), "");

  assertEquals(normalizeIntentProvider("mtn"), "mtn");
  assertEquals(normalizeIntentProvider("MTN"), "mtn");
  assertEquals(normalizeIntentProvider("Mtn"), "mtn");
  assertEquals(normalizeIntentProvider("mtn_momo_ben"), "mtn");
  assertEquals(normalizeIntentProvider("MTN_MOMO_BEN"), "mtn");

  assertEquals(normalizeIntentProvider("moov"), "moov");
  assertEquals(normalizeIntentProvider("MOOV"), "moov");
  assertEquals(normalizeIntentProvider("Moov"), "moov");
  assertEquals(normalizeIntentProvider("moov_ben"), "moov");
  assertEquals(normalizeIntentProvider("MOOV_BEN"), "moov");

  assertEquals(normalizeIntentProvider("celtiis"), "celtiis");
  assertEquals(normalizeIntentProvider("CELTIIS"), "celtiis");
  assertEquals(normalizeIntentProvider("Celtiis"), "celtiis");
  assertEquals(normalizeIntentProvider("celtiis_ben"), "celtiis");
  assertEquals(normalizeIntentProvider("CELTIIS_BEN"), "celtiis");

  assertEquals(normalizeIntentProvider("orange"), "");
  assertEquals(normalizeIntentProvider("airtel"), "");
  assertEquals(normalizeIntentProvider("unknown_provider"), "");
});

Deno.test("resolveSecureCallbackUrl", async () => {
  const { resolveSecureCallbackUrl } = await import("./db.ts");

  const url = await resolveSecureCallbackUrl();

  assertEquals(
    url,
    "https://example.com/fn/v1/payments_webhook",
  );
});

Deno.test("hasPartnerPaymentMarker", async () => {
  const { hasPartnerPaymentMarker } = await import("./handlers.ts");

  assertEquals(hasPartnerPaymentMarker({}), false);
  assertEquals(hasPartnerPaymentMarker({ amount: 5000 }), false);
  assertEquals(hasPartnerPaymentMarker({ product_sku: "premium_90d" }), false);

  assertEquals(hasPartnerPaymentMarker({ partner_code: "ABC123" }), true);
  assertEquals(hasPartnerPaymentMarker({ partnerCode: "ABC123" }), true);
  assertEquals(hasPartnerPaymentMarker({ partner_id: "abc-123" }), true);
  assertEquals(hasPartnerPaymentMarker({ partnerId: "abc-123" }), true);

  assertEquals(
    hasPartnerPaymentMarker({ metadata: { partner_code: "ABC123" } }),
    true,
  );
  assertEquals(
    hasPartnerPaymentMarker({ metadata: { partnerCode: "ABC123" } }),
    true,
  );
  assertEquals(
    hasPartnerPaymentMarker({ metadata: { partner_id: "abc-123" } }),
    true,
  );
  assertEquals(
    hasPartnerPaymentMarker({ metadata: { partnerId: "abc-123" } }),
    true,
  );

  assertEquals(hasPartnerPaymentMarker({ partner_code: "" }), false);
  assertEquals(hasPartnerPaymentMarker({ partner_code: "   " }), false);
  assertEquals(hasPartnerPaymentMarker({ partner_code: null }), false);

  assertEquals(
    hasPartnerPaymentMarker({ partner_code: "XYZ", metadata: {} }),
    true,
  );
  assertEquals(
    hasPartnerPaymentMarker({
      amount: 10000,
      metadata: { partnerCode: "P100" },
    }),
    true,
  );
});
