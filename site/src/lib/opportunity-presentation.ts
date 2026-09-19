export const ALL_FILTER_VALUE = "all";

const PUBLISHED_DATE_FORMATTER = new Intl.DateTimeFormat("en-GB", {
  day: "numeric",
  month: "short",
  year: "numeric",
  timeZone: "UTC",
});

export function getCountries(location: string): string[] {
  return [
    ...new Set(
      location
        .split(";")
        .map((item) => item.split(",").at(-1)?.trim() || item.trim())
        .filter(Boolean)
    ),
  ];
}

export function formatCategory(category: string): string {
  return category
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export function getCategoryHue(category: string): number {
  return [...category].reduce((hash, character) => (hash * 17 + character.charCodeAt(0)) % 360, 0);
}

export function getEmploymentTypeHue(employmentType: string): number {
  const hues: Record<string, number> = {
    internship: 265,
    "new-grad": 145,
  };
  return hues[employmentType] ?? 210;
}

export function parseOpportunityTimestamp(value: string): number {
  const isoValue = value.replace(" ", "T");
  return Date.parse(/(?:Z|[+-]\d{2}:\d{2})$/.test(isoValue) ? isoValue : `${isoValue}Z`);
}

export function formatPublishedDate(value: string): string {
  return PUBLISHED_DATE_FORMATTER.format(new Date(parseOpportunityTimestamp(value)));
}
