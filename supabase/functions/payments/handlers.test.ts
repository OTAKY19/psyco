import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { hasPartnerPaymentMarker, isPartnerPack } from "./handlers.ts";

Deno.test("hasPartnerPaymentMarker detects partner_code in body", () => {
  assertEquals(hasPartnerPaymentMarker({ partner_code: "CPB-001" }), true);
  assertEquals(hasPartnerPaymentMarker({ partnerCode: "CPB-001" }), true);
  assertEquals(hasPartnerPaymentMarker({ partner_id: "p1" }), true);
  assertEquals(hasPartnerPaymentMarker({ partnerId: "p1" }), true);
  assertEquals(hasPartnerPaymentMarker({ metadata: { partner_code: "X" } }), true);
  assertEquals(hasPartnerPaymentMarker({ metadata: { partnerCode: "X" } }), true);
  assertEquals(hasPartnerPaymentMarker({}), false);
  assertEquals(hasPartnerPaymentMarker({ metadata: {} }), false);
  assertEquals(hasPartnerPaymentMarker({ product_sku: "premium_90d" }), false);
});

Deno.test("hasPartnerPaymentMarker rejects non-string marker values", () => {
  assertEquals(hasPartnerPaymentMarker({ partner_code: 123 }), false);
  assertEquals(hasPartnerPaymentMarker({ partnerCode: null }), false);
  assertEquals(hasPartnerPaymentMarker({ partnerCode: undefined }), false);
  assertEquals(hasPartnerPaymentMarker({ metadata: { partner_id: true } }), false);
});

Deno.test("hasPartnerPaymentMarker rejects non-object metadata", () => {
  assertEquals(hasPartnerPaymentMarker({ metadata: "string" }), false);
  assertEquals(hasPartnerPaymentMarker({ metadata: null }), false);
  assertEquals(hasPartnerPaymentMarker({ metadata: 42 }), false);
});

Deno.test("isPartnerPack detects partner pack SKUs", () => {
  assertEquals(isPartnerPack("partner_pack_basic"), true);
  assertEquals(isPartnerPack("partner_pack_premium"), true);
  assertEquals(isPartnerPack("partner_pack_yearly_2026"), true);
  assertEquals(isPartnerPack("premium_90d"), false);
  assertEquals(isPartnerPack("license_access"), false);
  assertEquals(isPartnerPack(""), false);
  assertEquals(isPartnerPack("partner_pack_"), true);
});
