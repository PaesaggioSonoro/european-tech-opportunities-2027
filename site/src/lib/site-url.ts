import "server-only";

import {parseSiteUrl} from "@/lib/site-url-value";

export const siteUrl = parseSiteUrl(process.env.SITE_URL);
