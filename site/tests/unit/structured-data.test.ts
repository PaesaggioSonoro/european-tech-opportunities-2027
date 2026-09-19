import {describe, expect, test} from "bun:test";
import {buildStructuredData, serializeStructuredData} from "@/lib/structured-data";

describe("structured data", () => {
  test("describes the website, dataset, maintainer, and canonical downloads", () => {
    const structuredData = buildStructuredData(
      new URL("https://example.com/"),
      "2026-07-17T12:00:00+00:00"
    );
    const graph = structuredData["@graph"];

    expect(graph.find((item) => item["@type"] === "WebSite")).toMatchObject({
      "@id": "https://example.com/#website",
      url: "https://example.com/",
      mainEntity: {"@id": "https://example.com/#dataset"},
    });
    expect(graph.find((item) => item["@type"] === "Dataset")).toMatchObject({
      "@id": "https://example.com/#dataset",
      temporalCoverage: "2027",
      spatialCoverage: {"@type": "Place", name: "Europe"},
      license: "https://spdx.org/licenses/MIT.html",
      maintainer: {"@id": "https://simonesiega.com/#person"},
      "dcterms:accrualPeriodicity": {
        "@id": "http://purl.org/cld/freq/daily",
        name: "Daily",
      },
      dateModified: "2026-07-17T12:00:00+00:00",
      distribution: [
        {
          "@type": "DataDownload",
          encodingFormat: "text/csv",
          contentUrl: "https://example.com/open-opportunities.csv",
        },
        {
          "@type": "DataDownload",
          encodingFormat: "application/json",
          contentUrl: "https://example.com/open-opportunities.json",
        },
      ],
    });
    expect(graph.find((item) => item["@type"] === "Person")).toMatchObject({
      "@id": "https://simonesiega.com/#person",
      name: "Simone Siega",
    });

    const undatedDataset = buildStructuredData(new URL("https://example.com/"), null)[
      "@graph"
    ].find((item) => item["@type"] === "Dataset");
    expect(undatedDataset).not.toHaveProperty("dateModified");
  });

  test("escapes markup that could terminate the JSON-LD script", () => {
    const serialized = serializeStructuredData({value: "</script><script>alert(1)</script>"});

    expect(serialized).not.toContain("<");
    expect(JSON.parse(serialized)).toEqual({value: "</script><script>alert(1)</script>"});
  });
});
