import crypto from "node:crypto";
import fs from "node:fs";
import { HtmlBasePlugin } from "@11ty/eleventy";

const locales = { en: "en-GB", es: "es-ES" };

export default function (config) {
  config.addPlugin(HtmlBasePlugin);

  config.addPassthroughCopy({
    "src/assets": "assets",
    "src/files": "files",
    "src/css": "css",
    "src/js": "js",
    "src/blog/img": "blog/img",
  });

  config.addTransform("lazy-images", (content, path) => {
    if (!path || !path.endsWith(".html")) return content;
    return content.replace(/<img(?![^>]*loading=)(?![^>]*fetchpriority)/g, '<img loading="lazy" decoding="async"');
  });

  config.addFilter("day", (date, lang = "en") =>
    new Intl.DateTimeFormat(locales[lang], {
      day: "numeric",
      month: "long",
      year: "numeric",
      timeZone: "UTC",
    }).format(date),
  );

  config.addFilter("v", (file) =>
    crypto.createHash("md5").update(fs.readFileSync(`src/${file}`)).digest("hex").slice(0, 8),
  );

  config.addFilter("iso",(date) => date.toISOString().slice(0, 10));

  config.addFilter("bytes", (file) => {
    const size = fs.statSync(`src/files/${file}`).size;
    if (size < 1024 * 1024) return `${Math.round(size / 1024)} KB`;
    return `${(size / 1024 / 1024).toFixed(1)} MB`;
  });

  config.addFilter("clock", (seconds) => {
    const total = Math.round(seconds);
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
  });

  config.addFilter("minutes", (content) =>
    Math.max(1, Math.round(String(content).split(/\s+/).length / 220)),
  );

  config.addFilter("ofKind", (items, kind) => items.filter((item) => item.kind === kind));

  config.addFilter("english", (posts, thread) =>
    posts.find((post) => post.data.thread === thread && post.data.lang === "en"),
  );

  config.addCollection("posts",(api) =>
    api.getFilteredByGlob("src/blog/posts/*.md").sort((a, b) => b.date - a.date),
  );

  return {
    dir: { input: "src", includes: "_includes", data: "_data" },
    pathPrefix: "/streak/",
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
}
