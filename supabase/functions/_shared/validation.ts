import { HttpError } from "./errors.ts";

export function normalizeText(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim();
}

export function normalizeScalarText(value: unknown): string {
  if (typeof value === "string") return value.trim();
  if (typeof value === "number" || typeof value === "bigint") {
    return String(value).trim();
  }
  return "";
}

export function normalizePartnerCode(value: unknown): string {
  const raw = normalizeText(value).toUpperCase();
  if (!raw) return "";
  return raw.replace(/[^A-Z0-9]/g, "");
}

export function normalizeEmail(value: unknown): string {
  return normalizeText(value).toLowerCase();
}

export function normalizeProviderCode(value: unknown): string {
  const raw = normalizeText(value).toUpperCase();
  if (!raw) return "";
  return raw.replace(/[^A-Z0-9_]/g, "");
}

export function extractBearerToken(authorization: string | null): string {
  if (!authorization) return "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() ?? "";
}

export function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

export async function parseJsonBody(req: Request): Promise<Record<string, unknown>> {
  try {
    const body = await req.json();
    return asRecord(body);
  } catch {
    throw new HttpError(400, "Invalid JSON body");
  }
}

export function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

export function requireAppToken(
  req: Request,
  token: string,
  acceptBearer = false,
) {
  if (!token) {
    throw new HttpError(500, "[MISCONFIG] APP_TOKEN not configured");
  }

  const fromHeader = normalizeText(req.headers.get("x-app-token"));
  if (fromHeader && fromHeader === token) return;

  if (acceptBearer) {
    const fromBearer = extractBearerToken(req.headers.get("authorization"));
    if (fromBearer && fromBearer === token) return;
  }

  throw new HttpError(401, "Unauthorized");
}

export function normalizeTimestamp(value: unknown): string | null {
  if (value == null) return null;

  const raw = String(value).trim();
  if (!raw) return null;

  const hasTz = /(?:[zZ]|[+-]\d{2}:\d{2})$/.test(raw);
  const normalized = hasTz ? raw : `${raw}Z`;
  const parsed = new Date(normalized);

  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

export function extractFunctionPath(
  pathname: string,
  anchor: string,
): string {
  const segments = pathname.split("/").filter((segment) => segment.length > 0);
  const idx = segments.indexOf(anchor);
  if (idx === -1) return segments.join("/");
  return segments.slice(idx + 1).join("/");
}

export function safeNumber(
  val: string | null,
  fallback: number,
  min?: number,
  max?: number,
): number {
  if (val === null) return fallback;
  const n = Number(val);
  if (!Number.isFinite(n)) return fallback;
  if (min !== undefined && n < min) return min;
  if (max !== undefined && n > max) return max;
  return n;
}

export function escapeLikeWildcards(value: string): string {
  return value.replace(/[%_\\]/g, "\\$&");
}

export async function resolveAuthUserIdByEmail(
  email: string,
  supabaseUrl: string,
  serviceRoleKey: string,
): Promise<string | null> {
  if (!email) return null;
  const adminUrl = `${supabaseUrl}/auth/v1/admin/users?filter=email=eq.${encodeURIComponent(email)}`;
  const res = await fetch(adminUrl, {
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  });
  if (!res.ok) return null;
  const body = await res.json();
  if (Array.isArray(body) && body.length > 0) {
    return body[0].id ?? null;
  }
  return null;
}

