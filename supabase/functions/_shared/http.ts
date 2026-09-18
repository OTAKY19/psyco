import { HttpError } from "./errors.ts";

export function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
  headers: HeadersInit = {},
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...getCorsHeaders(),
      ...headers,
    },
  });
}

export function getCorsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") ?? "null",
    "Access-Control-Allow-Headers":
      "authorization, x-app-token, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  };
}

export function handleOptions(request: Request) {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: getCorsHeaders() });
  }
  return null;
}

export function jsonError(err: unknown): Response {
  if (err instanceof HttpError) {
    return jsonResponse(
      {
        error: {
          message: err.message,
          type: err.type ?? "http_error",
          code: err.code ?? "unknown",
          doc_url: err.doc_url ?? null,
          status: err.status,
        },
      },
      err.status,
    );
  }
  console.error("Unhandled error:", err);
  return jsonResponse(
    {
      error: {
        message: "Internal Server Error",
        type: "internal_error",
        code: "unknown",
        doc_url: null,
        status: 500,
      },
    },
    500,
  );
}
