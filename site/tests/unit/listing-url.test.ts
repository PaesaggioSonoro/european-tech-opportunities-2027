import {expect, test} from "bun:test";
import {isCanonicalListingUrl} from "@/lib/listing-url";

const jobId = "1000000001";

test("accepts only the canonical HTTPS LinkedIn listing matching the job ID", () => {
  expect(isCanonicalListingUrl(`https://www.linkedin.com/jobs/view/${jobId}`, jobId)).toBe(true);

  const rejectedUrls = [
    "https://www.linkedin.com/jobs/view/1000000002",
    `http://www.linkedin.com/jobs/view/${jobId}`,
    `https://linkedin.com/jobs/view/${jobId}`,
    `https://user@www.linkedin.com/jobs/view/${jobId}`,
    `https://www.linkedin.com/jobs/view/${jobId}?tracking=1`,
    `https://www.linkedin.com/jobs/view/${jobId}#details`,
    "javascript:alert(1)",
    "not-a-url",
  ];

  for (const url of rejectedUrls) {
    expect(isCanonicalListingUrl(url, jobId)).toBe(false);
  }

  expect(isCanonicalListingUrl(`https://www.linkedin.com/jobs/view/${jobId}`, "not-numeric")).toBe(
    false
  );
});
