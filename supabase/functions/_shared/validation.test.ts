import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { requireAppToken } from "./validation.ts";
import { HttpError } from "./errors.ts";

Deno.test("requireAppToken throws when token env var is empty", () => {
  const req = new Request("http://localhost", {
    headers: { "x-app-token": "anything" },
  });
  try {
    requireAppToken(req, "");
    throw new Error("should have thrown");
  } catch (e) {
    assertEquals(e instanceof HttpError, true);
    assertEquals((e as HttpError).status, 500);
    assertStringIncludes((e as HttpError).message, "MISCONFIG");
  }
});

Deno.test("requireAppToken passes with valid token", () => {
  const req = new Request("http://localhost", {
    headers: { "x-app-token": "valid-token" },
  });
  // Should not throw
  requireAppToken(req, "valid-token");
});

Deno.test("requireAppToken throws 401 with wrong token", () => {
  const req = new Request("http://localhost", {
    headers: { "x-app-token": "wrong-token" },
  });
  try {
    requireAppToken(req, "valid-token");
    throw new Error("should have thrown");
  } catch (e) {
    assertEquals(e instanceof HttpError, true);
    assertEquals((e as HttpError).status, 401);
  }
});
