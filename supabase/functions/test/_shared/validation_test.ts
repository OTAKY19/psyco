import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  normalizeText,
  normalizePartnerCode,
  isUuid,
  safeNumber,
  normalizeEmail,
  escapeLikeWildcards,
  extractBearerToken,
  normalizeTimestamp,
} from "../../_shared/validation.ts";

Deno.test("normalizeText trims whitespace and returns empty for non-strings", () => {
  assertEquals(normalizeText("  hello  "), "hello");
  assertEquals(normalizeText(""), "");
  assertEquals(normalizeText(123), "");
  assertEquals(normalizeText(null), "");
  assertEquals(normalizeText(undefined), "");
});

Deno.test("normalizePartnerCode removes non-alphanumeric chars and uppercases", () => {
  assertEquals(normalizePartnerCode(" abc-123 "), "ABC123");
  assertEquals(normalizePartnerCode("cpb--test_!"), "CPBTEST");
  assertEquals(normalizePartnerCode(""), "");
  assertEquals(normalizePartnerCode(123), "");
});

Deno.test("isUuid validates UUID v4 format", () => {
  assertEquals(isUuid("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isUuid("550e8400-e29b-41d4-a716-44665544000Z"), false);
  assertEquals(isUuid("not-a-uuid"), false);
  assertEquals(isUuid(""), false);
  assertEquals(isUuid("550e8400-e29b-51d4-a716-446655440000"), true);
});

Deno.test("safeNumber parses and clamps values correctly", () => {
  assertEquals(safeNumber("42", 0), 42);
  assertEquals(safeNumber(null, 10), 10);
  assertEquals(safeNumber("abc", 5), 5);
  assertEquals(safeNumber("150", 0, 1, 100), 100);
  assertEquals(safeNumber("-5", 0, 1), 1);
  assertEquals(safeNumber("50", 0, undefined, undefined), 50);
});

Deno.test("normalizeEmail lowercases and trims", () => {
  assertEquals(normalizeEmail("  Test@Example.COM  "), "test@example.com");
  assertEquals(normalizeEmail(""), "");
  assertEquals(normalizeEmail(null), "");
});

Deno.test("escapeLikeWildcards escapes % _ \\ characters", () => {
  assertEquals(escapeLikeWildcards("hello%world"), "hello\\%world");
  assertEquals(escapeLikeWildcards("test_123"), "test\\_123");
  assertEquals(escapeLikeWildcards("foo\\bar"), "foo\\\\bar");
  assertEquals(escapeLikeWildcards("normal"), "normal");
});

Deno.test("extractBearerToken extracts token from Authorization header", () => {
  assertEquals(extractBearerToken("Bearer my-token"), "my-token");
  assertEquals(extractBearerToken("bearer my-token"), "my-token");
  assertEquals(extractBearerToken(null), "");
  assertEquals(extractBearerToken(""), "");
  assertEquals(extractBearerToken("Basic credentials"), "");
});

Deno.test("normalizeTimestamp handles various ISO formats", () => {
  const result = normalizeTimestamp("2026-04-25T08:00:00");
  assertEquals(result, "2026-04-25T08:00:00.000Z");
  assertEquals(normalizeTimestamp(null), null);
  assertEquals(normalizeTimestamp(""), null);
  assertEquals(normalizeTimestamp("invalid"), null);
});
