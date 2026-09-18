import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

// pricing.ts creates a Supabase client at module level — set env before import
Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_ANON_KEY", "test-anon-key");

let computePromoAmount: (
  baseAmount: number,
  promo: { id: string; product_skus: string[]; name: string; discount_type: string; discount_value: number },
) => number;

const mod = await import("./pricing.ts");
computePromoAmount = mod.computePromoAmount;

Deno.test("computePromoAmount percentage discount 50%", () => {
  const result = computePromoAmount(5000, {
    id: "promo-1",
    product_skus: ["premium_90"],
    name: "Promo 50%",
    discount_type: "percentage",
    discount_value: 50,
  });
  assertEquals(result, 2500);
});

Deno.test("computePromoAmount fixed discount", () => {
  const result = computePromoAmount(5000, {
    id: "promo-2",
    product_skus: ["premium_90"],
    name: "Promo 1000 XOF",
    discount_type: "fixed",
    discount_value: 1000,
  });
  assertEquals(result, 4000);
});

Deno.test("computePromoAmount 100% percentage returns 0", () => {
  const result = computePromoAmount(5000, {
    id: "promo-3",
    product_skus: ["premium_90"],
    name: "100% OFF",
    discount_type: "percentage",
    discount_value: 100,
  });
  assertEquals(result, 0);
});

Deno.test("computePromoAmount fixed exceeds base returns 0", () => {
  const result = computePromoAmount(500, {
    id: "promo-4",
    product_skus: ["premium_90"],
    name: "Big discount",
    discount_type: "fixed",
    discount_value: 9999,
  });
  assertEquals(result, 0);
});

Deno.test("computePromoAmount zero base amount", () => {
  const result = computePromoAmount(0, {
    id: "promo-5",
    product_skus: ["free_item"],
    name: "Free",
    discount_type: "fixed",
    discount_value: 0,
  });
  assertEquals(result, 0);
});

Deno.test("computePromoAmount small percentage rounds correctly", () => {
  const result = computePromoAmount(99, {
    id: "promo-6",
    product_skus: ["premium_90"],
    name: "10%",
    discount_type: "percentage",
    discount_value: 10,
  });
  assertEquals(result, 89);
});

Deno.test("computePromoAmount handles fractional percentage", () => {
  const result = computePromoAmount(1999, {
    id: "promo-7",
    product_skus: ["premium_90"],
    name: "15%",
    discount_type: "percentage",
    discount_value: 15,
  });
  assertEquals(result, 1699);
});
