import { HttpError } from "./errors.ts";
import { normalizePartnerCode, normalizeText } from "./validation.ts";
import { type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type PartnerValidation = {
  valid: boolean;
  id?: string;
  code?: string;
  name?: string;
};

const PARTNERS_TABLE = "partners";

export async function validatePartner(
  client: SupabaseClient,
  code?: string,
): Promise<PartnerValidation> {
  const normalizedCode = normalizePartnerCode(code);
  if (!normalizedCode) return { valid: true };

  let { data, error } = await client
    .from(PARTNERS_TABLE)
    .select("id, active, code, name")
    .eq("code", normalizedCode)
    .maybeSingle();

  if (error) {
    throw new HttpError(500, "Failed partner validation");
  }

  if (!data) {
    const { data: ilikeData, error: ilikeError } = await client
      .from(PARTNERS_TABLE)
      .select("id, active, code, name")
      .ilike("code", normalizedCode)
      .maybeSingle();

    if (ilikeError) {
      throw new HttpError(500, "Failed partner validation");
    }
    data = ilikeData;
  }

  if (!data || data.active !== true) return { valid: false };

  return {
    valid: true,
    id: normalizeText(data.id),
    code: normalizeText(data.code).toUpperCase(),
    name: normalizeText(data.name),
  };
}
