import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { getCorsHeaders } from "./http.ts";

Deno.test("getCorsHeaders uses configured origin", () => {
  Deno.env.set("ALLOWED_ORIGIN", "https://codepermisbenin.app");
  const headers = getCorsHeaders();
  assertEquals(
    headers["Access-Control-Allow-Origin"],
    "https://codepermisbenin.app",
  );
});

Deno.test("getCorsHeaders falls back to no browser origin by default", () => {
  Deno.env.delete("ALLOWED_ORIGIN");
  const headers = getCorsHeaders();
  assertEquals(headers["Access-Control-Allow-Origin"], "null");
});
