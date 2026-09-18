import { handleOptions, jsonError, jsonResponse } from "../_shared/http.ts";
import { anonClient, createUserClient } from "../_shared/supabase.ts";
import { HttpError } from "../_shared/errors.ts";
import { extractBearerToken } from "../_shared/validation.ts";
import {
  computePromoAmount,
  loadActivePromos,
  promoAppliesToSku,
} from "../_shared/pricing.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

Deno.serve(async (req) => {
  const maybeOptions = handleOptions(req);
  if (maybeOptions) return maybeOptions;

  try {
    if (req.method !== "GET") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const clientIp =
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
    try {
      await checkRateLimit("config", clientIp, 20, 60);
    } catch (rateError) {
      if (rateError instanceof HttpError && rateError.status === 429) {
        throw rateError;
      }
      console.error(
        "Config rate limit check unavailable (non-blocking):",
        rateError,
      );
    }

    const token = extractBearerToken(req.headers.get("authorization"));
    const supabase = token ? createUserClient(token) : anonClient();

    const { data: products, error: productError } = await supabase
      .from("catalog_products")
      .select("*")
      .eq("is_active", true)
      .order("activation_code_quantity", {
        ascending: true,
        nullsFirst: false,
      });

    if (productError) {
      return jsonResponse({ error: productError.message }, 500);
    }

    const activePromos = await loadActivePromos();

    const productsWithPromo = (products ?? []).map(
      (p: Record<string, unknown>) => {
        const sku = p.sku as string;
        const promo = activePromos.find((pr) => promoAppliesToSku(pr, sku));
        if (!promo) return p;
        const base = p.amount_xof as number;
        const promoPrice = computePromoAmount(base, promo);
        return {
          ...p,
          promo_amount_xof: promoPrice,
          promo_name: promo.name,
          promo_discount_label: promo.discount_type === "percentage"
            ? `-${promo.discount_value}%`
            : `-${promo.discount_value} XOF`,
        };
      },
    );

    const { data: contactRows, error: contactError } = await supabase
      .from("company_contacts")
      .select("key, value");
    if (contactError) {
      return jsonResponse({ error: contactError.message }, 500);
    }
    const contacts: Record<string, string> = {};
    for (const row of contactRows ?? []) {
      contacts[row.key] = row.value;
    }

    const { data: appConfigRows, error: appConfigError } = await supabase
      .from("app_config")
      .select("key, value");
    if (appConfigError) {
      console.error(
        "[config] app_config fetch failed (fail-open):",
        appConfigError.message,
      );
    }
    const appConfig: Record<string, string> = {};
    for (const row of appConfigRows ?? []) {
      appConfig[row.key] = row.value;
    }

    const responseData = {
      ttl_seconds: 3600,
      products: productsWithPromo,
      contacts,
      app_config: appConfig,
    };
    return new Response(JSON.stringify(responseData), {
      headers: {
        "content-type": "application/json",
        "cache-control": "public, max-age=3600, stale-while-revalidate=86400",
      },
    });
  } catch (err) {
    return jsonError(err);
  }
});
