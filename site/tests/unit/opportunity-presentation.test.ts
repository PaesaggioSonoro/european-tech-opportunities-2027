import {describe, expect, test} from "bun:test";
import {formatPublishedDate, getCountries} from "@/lib/opportunity-presentation";

describe("opportunity presentation", () => {
  test("extracts every unique country from a multi-location value", () => {
    expect(getCountries("Madrid, Spain; Lisbon, Portugal; Porto, Portugal")).toEqual([
      "Spain",
      "Portugal",
    ]);
  });

  test("formats offset and SQLite timestamps consistently in UTC", () => {
    expect(formatPublishedDate("2026-07-17T23:30:00-02:00")).toBe("18 Jul 2026");
    expect(formatPublishedDate("2026-07-17 23:30:00")).toBe("17 Jul 2026");
  });
});
