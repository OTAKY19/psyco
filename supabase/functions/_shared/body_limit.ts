export async function parseJsonBody(
  req: Request,
  maxBytes = 100_000,
): Promise<Record<string, unknown>> {
  const contentLength = req.headers.get("content-length");
  if (contentLength && parseInt(contentLength, 10) > maxBytes) {
    return {};
  }

  const text = await req.text();
  if (text.length > maxBytes) {
    return {};
  }

  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return {};
  }
}
