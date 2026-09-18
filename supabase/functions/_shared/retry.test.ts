import { assertEquals, assertRejects, assertStrictEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { withRetry } from "./retry.ts";
import { HttpError } from "./errors.ts";

Deno.test("withRetry succeeds on first attempt", async () => {
  let calls = 0;
  const result = await withRetry(async () => {
    calls++;
    return "ok";
  });
  assertEquals(result, "ok");
  assertEquals(calls, 1);
});

Deno.test("withRetry succeeds after 1 retry", async () => {
  let calls = 0;
  const result = await withRetry(async () => {
    calls++;
    if (calls < 2) throw new TypeError("network error");
    return "recovered";
  }, { maxAttempts: 3, baseDelayMs: 10 });
  assertEquals(result, "recovered");
  assertEquals(calls, 2);
});

Deno.test("withRetry throws after exhausting attempts", async () => {
  let calls = 0;
  await assertRejects(
    () =>
      withRetry(async () => {
        calls++;
        throw new TypeError("persistent failure");
      }, { maxAttempts: 3, baseDelayMs: 10 }),
    TypeError,
    "persistent failure",
  );
  assertEquals(calls, 3);
});

Deno.test("withRetry does NOT retry on 4xx errors", async () => {
  let calls = 0;
  await assertRejects(
    () =>
      withRetry(async () => {
        calls++;
        throw new HttpError(422, "bad input");
      }, { maxAttempts: 3, baseDelayMs: 10 }),
    HttpError,
  );
  assertEquals(calls, 1);
});

Deno.test("withRetry retries on 5xx errors", async () => {
  let calls = 0;
  await assertRejects(
    () =>
      withRetry(async () => {
        calls++;
        if (calls < 3) throw new HttpError(502, "bad gateway");
        throw new HttpError(502, "still fails");
      }, { maxAttempts: 3, baseDelayMs: 10 }),
    HttpError,
  );
  assertEquals(calls, 3);
});

Deno.test("withRetry uses custom retryOn function", async () => {
  let calls = 0;
  const customError = new Error("custom-retry");
  await assertRejects(
    () =>
      withRetry(async () => {
        calls++;
        throw customError;
      }, {
        maxAttempts: 2,
        baseDelayMs: 10,
        retryOn: (err) => err === customError,
      }),
    Error,
  );
  assertEquals(calls, 2);
});
