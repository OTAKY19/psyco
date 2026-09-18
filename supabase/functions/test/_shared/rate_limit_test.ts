import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { HttpError } from "../../_shared/errors.ts";

// rate_limit.ts captures env vars at module load time (module-level const).
// Import must happen AFTER env vars are set.
const prevUrl = Deno.env.get("SUPABASE_URL");
const prevKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
Deno.env.set("SUPABASE_URL", "https://test.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "test-service-key");

const originalFetch = globalThis.fetch;
globalThis.fetch = async (input: RequestInfo | URL) => {
  const url = input instanceof Request ? input.url : String(input);
  if (url.includes("/rest/v1/rpc/check_rate_limit")) {
    return new Response("false", { status: 200 });
  }
  throw new Error(`Unexpected fetch call: ${url}`);
};

const { checkRateLimit } = await import("../../_shared/rate_limit.ts");

Deno.test("checkRateLimit throws 429 when RPC returns false", async () => {
  await assertRejects(
    () => checkRateLimit("test", "key", 3, 60),
    HttpError,
  );
});

Deno.test("checkRateLimit throws 500 when RPC returns error data", async () => {
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request ? input.url : String(input);
    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return new Response(
        JSON.stringify({ code: "INTERNAL_ERROR", message: "DB error" }),
        { status: 500 },
      );
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };
  await assertRejects(
    () => checkRateLimit("another", "key2"),
    HttpError,
  );
});

Deno.test("checkRateLimit passes when RPC returns true", async () => {
  globalThis.fetch = async (input: RequestInfo | URL) => {
    const url = input instanceof Request ? input.url : String(input);
    if (url.includes("/rest/v1/rpc/check_rate_limit")) {
      return new Response("true", { status: 200 });
    }
    throw new Error(`Unexpected fetch call: ${url}`);
  };
  await checkRateLimit("ok", "key3", 10, 60);
});

globalThis.fetch = originalFetch;
