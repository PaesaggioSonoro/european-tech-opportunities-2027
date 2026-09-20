import {expect, test} from "bun:test";
import {contentSecurityPolicy} from "../../next.config";

test("permits the hosted Umami script and analytics endpoint", () => {
  expect(contentSecurityPolicy).toContain(
    "script-src 'self' 'unsafe-inline' https://cloud.umami.is"
  );
  expect(contentSecurityPolicy).toContain("connect-src 'self' https://gateway.umami.is");
});
