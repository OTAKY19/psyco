import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

export type ActivePromo = {
  id: string;
  product_skus: string[];
  name: string;
  description?: string | null;
  discount_type: string;
  discount_value: number;
  max_uses?: number | null;
  current_uses?: number;
  starts_at?: string;
  ends_at?: string;
};

export async function loadActivePromos(): Promise<ActivePromo[]> {
  const now = new Date().toISOString();

  const { data: promos, error } = await supabase
    .from("promotions")
    .select("id, name, discount_type, discount_value, max_uses, current_uses")
    .eq("is_active", true)
    .lte("starts_at", now)
    .gte("ends_at", now);

  if (error || !promos) {
    console.error("Failed to load promotions:", error?.message ?? "no data");
    return [];
  }

  const promoIds = promos.map((p) => p.id);
  const { data: skuRows, error: skuError } = await supabase
    .from("promotion_skus")
    .select("promotion_id, product_sku")
    .in("promotion_id", promoIds);

  if (skuError) {
    console.error("Failed to load promotion_skus:", skuError.message);
    return [];
  }

  const skuMap: Record<string, string[]> = {};
  for (const row of skuRows) {
    if (!skuMap[row.promotion_id]) skuMap[row.promotion_id] = [];
    skuMap[row.promotion_id].push(row.product_sku);
  }

  const result: ActivePromo[] = [];
  for (const p of promos) {
    if (p.max_uses != null && p.current_uses >= p.max_uses) continue;
    result.push({
      id: p.id,
      product_skus: skuMap[p.id] ?? [],
      name: p.name,
      discount_type: p.discount_type,
      discount_value: p.discount_value,
    });
  }
  return result;
}

export function promoAppliesToSku(promo: ActivePromo, sku: string): boolean {
  return promo.product_skus.includes(sku) || promo.product_skus.includes("__all__");
}

/** @deprecated Use loadActivePromos() + promoAppliesToSku() instead */
export async function loadActivePromoForSku(
  sku: string,
): Promise<ActivePromo | null> {
  const promos = await loadActivePromos();
  return promos.find((p) => promoAppliesToSku(p, sku)) ?? null;
}

export function computePromoAmount(
  baseAmount: number,
  promo: ActivePromo,
): number {
  if (promo.discount_type === "percentage") {
    return Math.max(
      0,
      baseAmount - Math.round(baseAmount * promo.discount_value / 100),
    );
  }
  return Math.max(0, baseAmount - promo.discount_value);
}
