import {describe, expect, test} from "bun:test";
import {parseSiteUrl} from "@/lib/site-url-value";

describe("site URL validation", () => {
  test("accepts canonical HTTP and HTTPS origins", () => {
    expect(parseSiteUrl(undefined).toString()).toBe("http://localhost:3000/");
    expect(parseSiteUrl("https://opportunities2027.simonesiega.com").toString()).toBe(
      "https://opportunities2027.simonesiega.com/"
    );
  });

  test("rejects values that are unsafe or are not origins", () => {
    const invalidValues = [
      "not-a-url",
      "ftp://example.com",
      "https://user@example.com",
      "https://example.com/directory",
      "https://example.com/?source=test",
      "https://example.com/#directory",
    ];

    for (const value of invalidValues) {
      expect(() => parseSiteUrl(value)).toThrow("SITE_URL must be an HTTP(S) origin");
    }
  });
});
