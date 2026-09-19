export const DIRECTORY_PAGE_SIZES = [10, 20, 30, 50, 100] as const;
export const DIRECTORY_SORTS = [
  "company-asc",
  "company-desc",
  "role-asc",
  "role-desc",
  "location-asc",
  "location-desc",
  "first-seen-asc",
  "first-seen-desc",
] as const;

export type DirectoryPageSize = (typeof DIRECTORY_PAGE_SIZES)[number];
export type DirectorySort = (typeof DIRECTORY_SORTS)[number];

export type DirectoryView = {
  sort: DirectorySort;
  page: number;
  pageSize: DirectoryPageSize;
};
