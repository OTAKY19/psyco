import { assertEquals, assertExists, assertStringIncludes } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { HttpError } from "./errors.ts";

Deno.env.set("FEDAPAY_API_URL", "https://sandbox-api.fedapay.com/v1");
Deno.env.set("FEDAPAY_API_TOKEN", "test-token");

const fedapay = await import("./fedapay.ts");

async function computeHmacSha256Base64(
  body: string,
  secret: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(body),
  );
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

Deno.test("normalizeCurrency returns XOF for valid XOF input", () => {
  assertEquals(fedapay.normalizeCurrency("XOF"), "XOF");
});

Deno.test("normalizeCurrency uppercases lowercase input", () => {
  assertEquals(fedapay.normalizeCurrency("usd"), "USD");
});

Deno.test("normalizeCurrency defaults to XOF for empty string", () => {
  assertEquals(fedapay.normalizeCurrency(""), "XOF");
});

Deno.test("normalizeCurrency defaults to XOF for too-short code", () => {
  assertEquals(fedapay.normalizeCurrency("A"), "XOF");
});

Deno.test("normalizeCountryIso3 converts BJ to BEN", () => {
  assertEquals(fedapay.normalizeCountryIso3("BJ"), "BEN");
});

Deno.test("normalizeCountryIso3 keeps BEN as BEN", () => {
  assertEquals(fedapay.normalizeCountryIso3("BEN"), "BEN");
});

Deno.test("normalizeCountryIso3 returns non-BJ 2-letter code as-is", () => {
  assertEquals(fedapay.normalizeCountryIso3("CI"), "CI");
});

Deno.test("normalizeCountryIso3 defaults to BEN for empty input", () => {
  assertEquals(fedapay.normalizeCountryIso3(""), "BEN");
});

Deno.test("countryIso3ToIso2 converts BEN to BJ", () => {
  assertEquals(fedapay.countryIso3ToIso2("BEN"), "BJ");
});

Deno.test("countryIso3ToIso2 returns BJ as-is", () => {
  assertEquals(fedapay.countryIso3ToIso2("BJ"), "BJ");
});

Deno.test("countryIso3ToIso2 returns other 2-letter code as-is", () => {
  assertEquals(fedapay.countryIso3ToIso2("CI"), "CI");
});

Deno.test("normalizePhoneE164 keeps valid +229 number unchanged", () => {
  assertEquals(fedapay.normalizePhoneE164("+22990000000", "BEN"), "+22990000000");
});

Deno.test("normalizePhoneE164 adds 229 prefix for local Benin number", () => {
  assertEquals(fedapay.normalizePhoneE164("90000000", "BEN"), "+22990000000");
});

Deno.test("normalizePhoneE164 handles number with 229 prefix without +", () => {
  assertEquals(fedapay.normalizePhoneE164("22990000000", "BEN"), "+22990000000");
});

Deno.test("normalizePhoneE164 returns empty for empty input", () => {
  assertEquals(fedapay.normalizePhoneE164("", "BEN"), "");
});

Deno.test("sanitizePhoneNumber strips +229 prefix", () => {
  assertEquals(fedapay.sanitizePhoneNumber("+22990000000"), "90000000");
});

Deno.test("sanitizePhoneNumber strips 229 prefix without +", () => {
  assertEquals(fedapay.sanitizePhoneNumber("22990000000"), "90000000");
});

Deno.test("sanitizePhoneNumber returns empty for empty input", () => {
  assertEquals(fedapay.sanitizePhoneNumber(""), "");
});

Deno.test("resolveNoRedirectMode maps MTN_MOMO_BEN to mtn", () => {
  assertEquals(fedapay.resolveNoRedirectMode("MTN_MOMO_BEN"), "mtn");
});

Deno.test("resolveNoRedirectMode maps MOOV_BEN to moov", () => {
  assertEquals(fedapay.resolveNoRedirectMode("MOOV_BEN"), "moov");
});

Deno.test("resolveNoRedirectMode maps CELTIIS_BEN to celtiis", () => {
  assertEquals(fedapay.resolveNoRedirectMode("CELTIIS_BEN"), "celtiis");
});

Deno.test("resolveNoRedirectMode maps MTN to mtn", () => {
  assertEquals(fedapay.resolveNoRedirectMode("MTN"), "mtn");
});

Deno.test("resolveNoRedirectMode returns empty for unknown code", () => {
  assertEquals(fedapay.resolveNoRedirectMode("UNKNOWN"), "");
});

Deno.test("resolveNoRedirectMode returns empty for empty input", () => {
  assertEquals(fedapay.resolveNoRedirectMode(""), "");
});

Deno.test("normalizeMetadata flattens mixed types to strings", () => {
  const result = fedapay.normalizeMetadata({
    key: "value",
    num: 42,
    flag: true,
  });
  assertEquals(result, { key: "value", num: "42", flag: "true" });
});

Deno.test("normalizeMetadata skips empty strings and null values", () => {
  const result = fedapay.normalizeMetadata({ empty: "", skip: null });
  assertEquals(result, {});
});

Deno.test("normalizeMetadata returns empty object for null input", () => {
  assertEquals(fedapay.normalizeMetadata(null), {});
});

Deno.test("normalizeMetadata returns empty object for undefined input", () => {
  assertEquals(fedapay.normalizeMetadata(undefined), {});
});

Deno.test("pickMetadataValue returns first non-empty value", () => {
  const result = fedapay.pickMetadataValue(
    { a: "ok", b: "no" },
    ["a", "b"],
  );
  assertEquals(result, "ok");
});

Deno.test("pickMetadataValue returns empty when all keys are missing or empty", () => {
  const result = fedapay.pickMetadataValue(
    { a: "" },
    ["a", "b"],
  );
  assertEquals(result, "");
});

Deno.test("computePremiumUntilIso returns valid ISO string with default duration", () => {
  const result = fedapay.computePremiumUntilIso(undefined);
  const date = new Date(result);
  assertEquals(Number.isNaN(date.getTime()), false);
  assertStringIncludes(result, "T");
  assertStringIncludes(result, "Z");
});

Deno.test("computePremiumUntilIso with 30 returns date ~30 days from now", () => {
  const result = fedapay.computePremiumUntilIso(30);
  const resultDate = new Date(result);
  assertEquals(Number.isNaN(resultDate.getTime()), false);
  const now = new Date();
  const diffDays = (resultDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
  assertEquals(diffDays > 29, true);
  assertEquals(diffDays < 31, true);
});

Deno.test("mapFedaStatusToInternal maps approved to completed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("approved"), "completed");
});

Deno.test("mapFedaStatusToInternal maps transferred to completed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("transferred"), "completed");
});

Deno.test("mapFedaStatusToInternal maps pending to pending", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("pending"), "pending");
});

Deno.test("mapFedaStatusToInternal maps declined to failed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("declined"), "failed");
});

Deno.test("mapFedaStatusToInternal maps canceled to failed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("canceled"), "failed");
});

Deno.test("mapFedaStatusToInternal maps deleted to failed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("deleted"), "failed");
});

Deno.test("mapFedaStatusToInternal maps refunded to failed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("refunded"), "failed");
});

Deno.test("mapFedaStatusToInternal maps expired to failed", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("expired"), "failed");
});

Deno.test("mapFedaStatusToInternal maps not_found to not_found", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("not_found"), "not_found");
});

Deno.test("mapFedaStatusToInternal defaults unknown to pending", () => {
  assertEquals(fedapay.mapFedaStatusToInternal("unknown_status"), "pending");
});

Deno.test("mapInternalStatusToPaymentIntentStatus maps completed to completed", () => {
  assertEquals(fedapay.mapInternalStatusToPaymentIntentStatus("completed"), "completed");
});

Deno.test("mapInternalStatusToPaymentIntentStatus maps failed to failed", () => {
  assertEquals(fedapay.mapInternalStatusToPaymentIntentStatus("failed"), "failed");
});

Deno.test("mapInternalStatusToPaymentIntentStatus maps pending to pending", () => {
  assertEquals(fedapay.mapInternalStatusToPaymentIntentStatus("pending"), "pending");
});

Deno.test("mapInternalStatusToPaymentIntentStatus maps not_found to failed", () => {
  assertEquals(fedapay.mapInternalStatusToPaymentIntentStatus("not_found"), "failed");
});

Deno.test("mapInternalStatusToPaymentIntentStatus defaults unknown to pending", () => {
  assertEquals(fedapay.mapInternalStatusToPaymentIntentStatus("unknown"), "pending");
});

Deno.test("extractFailureMessage extracts top-level message", () => {
  assertEquals(fedapay.extractFailureMessage({ message: "error msg" }), "error msg");
});

Deno.test("extractFailureMessage extracts error field", () => {
  assertEquals(fedapay.extractFailureMessage({ error: "err" }), "err");
});

Deno.test("extractFailureMessage extracts detail field", () => {
  assertEquals(fedapay.extractFailureMessage({ detail: "detail msg" }), "detail msg");
});

Deno.test("extractFailureMessage formats last_error_code", () => {
  assertEquals(
    fedapay.extractFailureMessage({ last_error_code: "E001" }),
    "FedaPay error: E001",
  );
});

Deno.test("extractFailureMessage extracts nested data.message", () => {
  assertEquals(
    fedapay.extractFailureMessage({ data: { message: "nested" } }),
    "nested",
  );
});

Deno.test("extractFailureMessage returns empty for unknown payload", () => {
  assertEquals(fedapay.extractFailureMessage({ unknown: "val" }), "");
});

Deno.test("buildCustomer builds customer with all fields", () => {
  const result = fedapay.buildCustomer(
    {
      email: "test@example.com",
      firstname: "John",
      lastname: "Doe",
      phone: "+22990000000",
    },
    "BEN",
  );
  assertEquals(result.email, "test@example.com");
  assertEquals(result.firstname, "John");
  assertEquals(result.lastname, "Doe");
  assertEquals(result.phone_number, { number: "90000000", country: "BJ" });
});

Deno.test("buildCustomer handles camelCase field names", () => {
  const result = fedapay.buildCustomer(
    {
      email: "test@example.com",
      firstName: "John",
      lastName: "Doe",
      phone: "+22990000000",
    },
    "BEN",
  );
  assertEquals(result.email, "test@example.com");
  assertEquals(result.firstname, "John");
  assertEquals(result.lastname, "Doe");
});

Deno.test("buildCustomer returns empty object for empty input", () => {
  const result = fedapay.buildCustomer({}, "BEN");
  assertEquals(result, {});
});

Deno.test("createFedaPayTransaction returns transaction data on success", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            "v1/transaction": {
              id: 12345,
              reference: "REF-ABC-123",
              status: "approved",
              payment_url: "https://checkout.fedapay.com/abc",
              payment_token: "tok_abc123",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );

    const result = await fedapay.createFedaPayTransaction({
      amount: 5000,
      currency: "XOF",
      description: "Test payment",
      customer: { email: "test@test.com" },
      customMetadata: {},
    });

    assertEquals(result.transactionId, 12345);
    assertEquals(result.reference, "REF-ABC-123");
    assertEquals(result.status, "approved");
    assertEquals(result.checkoutUrl, "https://checkout.fedapay.com/abc");
    assertEquals(result.token, "tok_abc123");
    assertExists(result.raw);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("createFedaPayTransaction throws HttpError 502 on failure", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({ message: "Bad gateway" }),
          { status: 502, headers: { "Content-Type": "application/json" } },
        ),
      );

    let thrown: Error | null = null;
    try {
      await fedapay.createFedaPayTransaction({
        amount: 5000,
        currency: "XOF",
        description: "Test payment",
        customer: { email: "test@test.com" },
        customMetadata: {},
      });
    } catch (e) {
      thrown = e as Error;
    }

    assertExists(thrown);
    assertEquals(thrown instanceof HttpError, true);
    assertEquals((thrown as HttpError).status, 502);
    assertStringIncludes((thrown as HttpError).message, "Bad gateway");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("sendFedaPayNoRedirectPayment returns pending status on success", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({ status: "pending" }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );

    const result = await fedapay.sendFedaPayNoRedirectPayment("mtn", "tok_abc");
    assertEquals(result.status, "pending");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("sendFedaPayNoRedirectPayment throws HttpError 502 on 400", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({ message: "Invalid phone number" }),
          { status: 400, headers: { "Content-Type": "application/json" } },
        ),
      );

    let thrown: Error | null = null;
    try {
      await fedapay.sendFedaPayNoRedirectPayment("mtn", "tok_abc");
    } catch (e) {
      thrown = e as Error;
    }

    assertExists(thrown);
    assertEquals(thrown instanceof HttpError, true);
    assertEquals((thrown as HttpError).status, 502);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("sendFedaPayNoRedirectPayment sends phone number when provided", async () => {
  const originalFetch = globalThis.fetch;
  try {
    let capturedBody: string | undefined;
    globalThis.fetch = (_url: URL | RequestInfo, init?: RequestInit) => {
      capturedBody = init?.body as string;
      return Promise.resolve(
        new Response(
          JSON.stringify({ status: "pending" }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
    };

    await fedapay.sendFedaPayNoRedirectPayment(
      "mtn",
      "tok_abc",
      { number: "90000000", country: "BJ" },
    );

    const parsed = JSON.parse(capturedBody!);
    assertEquals(parsed.token, "tok_abc");
    assertEquals(parsed.phone_number.number, "90000000");
    assertEquals(parsed.phone_number.country, "BJ");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("fetchFedaPayTransaction returns status for approved transaction", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({ status: "approved" }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );

    const result = await fedapay.fetchFedaPayTransaction("12345");
    assertEquals(result.status, "approved");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("fetchFedaPayTransaction returns not_found on 404", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({}),
          { status: 404, headers: { "Content-Type": "application/json" } },
        ),
      );

    const result = await fedapay.fetchFedaPayTransaction("99999");
    assertEquals(result.status, "not_found");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("fetchFedaPayTransaction throws HttpError 502 on server error", async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = (_url: URL | RequestInfo, _init?: RequestInit) =>
      Promise.resolve(
        new Response(
          JSON.stringify({ message: "Server error" }),
          { status: 500, headers: { "Content-Type": "application/json" } },
        ),
      );

    let thrown: Error | null = null;
    try {
      await fedapay.fetchFedaPayTransaction("12345");
    } catch (e) {
      thrown = e as Error;
    }

    assertExists(thrown);
    assertEquals(thrown instanceof HttpError, true);
    assertEquals((thrown as HttpError).status, 502);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("verifyFedaPayWebhookSignature returns false for empty secret", async () => {
  const result = await fedapay.verifyFedaPayWebhookSignature(
    '{"event":"test"}',
    "some-signature",
    "",
  );
  assertEquals(result, false);
});

Deno.test("verifyFedaPayWebhookSignature returns false for empty signature header", async () => {
  const result = await fedapay.verifyFedaPayWebhookSignature(
    '{"event":"test"}',
    null,
    "secret",
  );
  assertEquals(result, false);
});

Deno.test("verifyFedaPayWebhookSignature returns true for matching signature", async () => {
  const body = JSON.stringify({ event: "test" });
  const secret = "test-secret";
  const signature = await computeHmacSha256Base64(body, secret);

  const result = await fedapay.verifyFedaPayWebhookSignature(
    body,
    signature,
    secret,
  );
  assertEquals(result, true);
});

Deno.test("verifyFedaPayWebhookSignature returns false for wrong signature", async () => {
  const body = JSON.stringify({ event: "test" });
  const secret = "test-secret";
  const wrongSignature = "dXNlciBjb25maXJtZWQh";

  const result = await fedapay.verifyFedaPayWebhookSignature(
    body,
    wrongSignature,
    secret,
  );
  assertEquals(result, false);
});

// --- FedaPay mode toggle tests ---

function makeMockSupabase(
  result: { value: string | null } | null,
  error: Error | null,
) {
  return {
    from: () => ({
      select: () => ({
        eq: () => ({
          maybeSingle: async () => {
            if (error) throw error;
            return { data: result, error: null };
          },
        }),
      }),
    }),
  } as any;
}

Deno.test("refreshFedaPayConfig reads sandbox from app_config", async () => {
  const mockSupabase = makeMockSupabase({ value: "sandbox" }, null);

  const config = await fedapay.refreshFedaPayConfig(mockSupabase);
  assertEquals(config.environment, "sandbox");

  const originalFetch = globalThis.fetch;
  try {
    let capturedUrl = "";
    globalThis.fetch = (input: RequestInfo | URL, _init?: RequestInit) => {
      capturedUrl = input instanceof Request ? input.url : String(input);
      return Promise.resolve(
        new Response(
          JSON.stringify({
            "v1/transaction": {
              id: 12345, reference: "REF-TEST", status: "approved",
              payment_url: "https://checkout.fedapay.com/abc",
              payment_token: "tok_abc123",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
    };

    await fedapay.createFedaPayTransaction({
      amount: 1000, currency: "XOF",
      description: "test",
      customer: { email: "test@test.com" },
      customMetadata: {},
    });

    assertStringIncludes(capturedUrl, "sandbox-api.fedapay.com");
  } finally {
    globalThis.fetch = originalFetch;
    await fedapay.refreshFedaPayConfig(makeMockSupabase(null, null));
  }
});

Deno.test("refreshFedaPayConfig falls back to env var on DB error", async () => {
  const mockSupabase = makeMockSupabase(
    null, new Error("DB error"),
  );

  const config = await fedapay.refreshFedaPayConfig(mockSupabase);
  assertEquals(config.environment, "live");

  const originalFetch = globalThis.fetch;
  const originalApiUrl = Deno.env.get("FEDAPAY_API_URL");
  Deno.env.delete("FEDAPAY_API_URL");
  try {
    let capturedUrl = "";
    globalThis.fetch = (input: RequestInfo | URL, _init?: RequestInit) => {
      capturedUrl = input instanceof Request ? input.url : String(input);
      return Promise.resolve(
        new Response(
          JSON.stringify({
            "v1/transaction": {
              id: 54321, reference: "REF-FALLBACK", status: "approved",
              payment_url: "https://checkout.fedapay.com/fallback",
              payment_token: "tok_fallback",
            },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
    };

    await fedapay.createFedaPayTransaction({
      amount: 2000, currency: "XOF",
      description: "fallback test",
      customer: { email: "test@test.com" },
      customMetadata: {},
    });

    assertStringIncludes(capturedUrl, "api.fedapay.com");
  } finally {
    if (originalApiUrl) Deno.env.set("FEDAPAY_API_URL", originalApiUrl);
    globalThis.fetch = originalFetch;
    await fedapay.refreshFedaPayConfig(makeMockSupabase(null, null));
  }
});

Deno.test("getCurrentEnvironment returns env var fallback when config is null", async () => {
  await fedapay.refreshFedaPayConfig(makeMockSupabase(null, new Error("DB error")));
  Deno.env.set("FEDAPAY_MODE", "sandbox");
  const env = fedapay.getCurrentEnvironment();
  assertEquals(env, "sandbox");
  Deno.env.delete("FEDAPAY_MODE");
  await fedapay.refreshFedaPayConfig(makeMockSupabase(null, null));
});

Deno.test("getCurrentEnvironment returns live when no config and no env var", async () => {
  await fedapay.refreshFedaPayConfig(makeMockSupabase(null, new Error("DB error")));
  Deno.env.delete("FEDAPAY_MODE");
  const env = fedapay.getCurrentEnvironment();
  assertEquals(env, "live");
  await fedapay.refreshFedaPayConfig(makeMockSupabase(null, null));
});

Deno.test("getCurrentEnvironment returns cached config after refresh", async () => {
  await fedapay.refreshFedaPayConfig(makeMockSupabase({ value: "sandbox" }, null));
  const env = fedapay.getCurrentEnvironment();
  assertEquals(env, "sandbox");
  await fedapay.refreshFedaPayConfig(makeMockSupabase({ value: "live" }, null));
});
