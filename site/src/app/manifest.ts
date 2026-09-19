import type {MetadataRoute} from "next";
import {siteConfig} from "@/lib/site-config";

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: "/",
    scope: "/",
    start_url: "/",
    name: siteConfig.name,
    short_name: siteConfig.shortName,
    description: siteConfig.description,
    lang: siteConfig.language,
    dir: "ltr",
    display: "standalone",
    background_color: "#f9fafb",
    theme_color: "#01123c",
    icons: [{src: "/icon.svg", sizes: "any", type: "image/svg+xml"}],
  };
}
