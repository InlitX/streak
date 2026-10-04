# Streak web

The website for Streak, built with [Eleventy](https://www.11ty.dev). It lives on
the `web` branch only, so `main` stays clean. GitHub Actions builds it and
publishes it to GitHub Pages on every push to `web`.

```
src/
  index.njk              home page
  blog/posts/            blog posts in Markdown, one file per language
  blog/img/              images used by the posts
  resources/index.njk    the resources page
  _data/resources.json   what the resources page lists
  _data/site.json        version, links and the comments settings
  _includes/             layouts and small macros
  files/                 the downloadable resources
  assets/                phones, previews, store icons
  css/ js/               styles and scripts
```

## Run it locally

```bash
npm install
npm run dev
```

Then open http://localhost:8080/streak/. It reloads on every change.

## Write a post

Create `src/blog/posts/my-post.md`:

```md
---
title: The title
description: One line for the list and for search engines.
date: 2026-10-04
lang: en
thread: my-post
translation: /es/blog/my-post/
---

Write in Markdown. Put images in `src/blog/img/` and use them like this:

![What the image shows](/blog/img/my-image.webp)
```

The Spanish version is `my-post.es.md` with `lang: es`, the same `thread` and
`translation: /blog/my-post/`. Both share one comment thread. A post without a
translation just leaves `translation` out.

## Comments and likes

Posts use [giscus](https://giscus.app): readers sign in with GitHub to comment
and react, and everything is stored as a discussion in `InlitX/streak`. To
switch it on:

1. Enable Discussions in the repository settings and add a category named `Blog`
   (type Announcement, so only giscus creates threads).
2. Install the giscus app on the repository.
3. On giscus.app, enter `InlitX/streak`, pick the `Blog` category and copy the
   `data-category-id` into `giscus.categoryId` in `src/_data/site.json`.

Until then, posts show a short note where the comments go.

## Add a resource

Put the file in `src/files/`, a preview in `src/assets/res/` and a line in
`src/_data/resources.json`. Sizes are read at build time. Add `"author"` to
credit someone. People send resources through the `Submit a resource` issue
form in the main repository; check the source and license before adding one.
