# Tika — Architecture

## Component Overview

```
bin/tika                  Entry point — parses ARGV, delegates to CLI.start
lib/tika/
  cli.rb                  Command dispatcher (OptionParser); routes to Builder/Server
  config.rb               Loads config.yml into a Hash subclass with method accessors
  builder.rb              Orchestrates full site build: load → render → write
  renderer.rb             ERB rendering engine; binds locals as instance vars on RenderContext
  server.rb               WEBrick dev server — builds once on start, serves build/
  models/
    article.rb            Parses YYYY-MM-DD-slug.md; exposes metadata + rendered HTML body
    page.rb               Parses content/pages/*.md; exposes slug, title, rendered body
assets/
  themes/                 Bundled themes (default, blue, corporate)
  example-site/           Sample content used as a test fixture
spec/                     Requirements, architecture, and acceptance criteria (this directory)
test/
  unit/                   Tests for Config, Article, Page, Renderer, Builder
  integration/            CLI commands + full sample-site end-to-end
```

## Data Flow: `tika build`

```
CLI#cmd_build
  └─ Config.load("config.yml")
  └─ Builder.new(config).build
       ├─ load_articles   → Dir.glob(content/articles/**/*.md) → Array<Article>
       ├─ load_pages      → Dir.glob(content/pages/*.md)       → Array<Page>
       ├─ sort + group    → articles by date desc; categories Hash
       │
       ├─ build_home         → home.html.erb (paginated)   → build/index.html
       │                                                      build/page/N/index.html
       ├─ build_articles     → article.html.erb per article → build/YYYY/MM/DD/slug/index.html
       ├─ build_categories   → category.html.erb per cat   → build/<category>/index.html
       ├─ build_archives     → archives.html.erb            → build/archives/index.html
       ├─ build_pages        → page.html.erb per page       → build/<slug>/index.html
       ├─ build_feed         → feed.xml.erb                 → build/feed.atom
       ├─ build_robots       → static string                → build/robots.txt
       └─ copy_assets        → themes/<name>/static/        → build/static/
                             → content/images/              → build/images/
```

## Rendering Pipeline

Every page goes through `Renderer#render(template, locals)`:

1. A `RenderContext` instance is created — a plain Ruby object that serves as the ERB binding
2. All `locals` keys are set as instance variables (`@article`, `@articles`, `@category`, etc.)
3. `@config` and `@pages` are always injected
4. The partial template (e.g. `article.html.erb`) is rendered against the context
5. `layout.html.erb` is rendered against the same context; `yield_content` returns the partial's output

Templates have no access to Builder or CLI internals — all data is explicit via locals.

## Content File Conventions

### Articles

Path: `content/articles/[<category>/]YYYY-MM-DD-<slug>.md`

- Subdirectory name (if any) becomes the article's category
- Filename prefix sets the publication date; everything after is the slug
- Extension: `.md` or `.txt`

Frontmatter (YAML between `---` delimiters):

```yaml
---
title: My Post Title # falls back to slug if absent
author: Name # falls back to config.author if absent
category: override # overrides directory-inferred category (optional)
---
Markdown body here.

<!--more-->

Content after the fold.
```

Any additional frontmatter key is accessible in templates as `@article.<key>`. Keys are normalized to lowercase.

The `<!--more-->` marker splits body from summary. If absent, the first paragraph is used as the summary.

### Pages

Path: `content/pages/<slug>.md` (or `.txt`, `.erb`)

```yaml
---
title: About
---
Markdown body.
```

### Drafts

Path: `content/drafts/YYYY-MM-DD-<slug>.md`

Same format as articles. Ignored by the builder unless `--drafts` flag is passed (`[planned]`).

## Config Schema

```yaml
# Required
title: "My Blog"
author: "Your Name"
base_url: "https://example.com" # no trailing slash
theme: "default"
content_dir: "content"
build_dir: "build"

# Optional
description: "Site tagline"
posts_per_page: 10
feed_entries: 10
permalink_style: "year_month_day" # only supported value currently
date_format: "%B %e, %Y" # strftime; %e is POSIX-portable (space-padded day)
```

`Config` subclasses `Hash`, so values are accessible as both `config["title"]` and `config.title`.

## Template Variables

Available in all templates via `@`:

| Variable      | Type                 | Always set?     | Description                               |
| ------------- | -------------------- | --------------- | ----------------------------------------- |
| `@config`     | `Config`             | yes             | Full site config                          |
| `@pages`      | `Array<Page>`        | yes             | All custom pages (used for nav links)     |
| `@categories` | `Hash<String,Array>` | yes             | Category name → sorted Array<Article>     |
| `@articles`   | `Array<Article>`     | home/cat/arch   | Articles for the current view             |
| `@article`    | `Article`            | article pages   | The single article being rendered         |
| `@page`       | `Page`               | page pages      | The custom page being rendered            |
| `@page_title` | `String`             | set by template | Set in partials; used in layout `<title>` |
| `@next_url`   | `String\|nil`        | home pages      | URL of the older pagination page          |
| `@prev_url`   | `String\|nil`        | home pages      | URL of the newer pagination page          |
| `@category`   | `String`             | category pages  | Current category name                     |

`layout.html.erb` calls `yield_content` to insert the rendered partial.

## Key Design Decisions

**No CLI framework** — `OptionParser` (stdlib) handles subcommand dispatch and flag parsing. Keeps the runtime
dependency surface to one gem (`kramdown`). Tradeoff: ~40 lines of plumbing vs. zero additional dependencies.

**Config as Hash subclass** — allows both `config["key"]` and `config.key` access without a separate accessor layer.
Method-missing delegates unknown method names to `self[name.to_s]`.

**RenderContext binding** — ERB templates execute against a plain Ruby object, not the Builder or a global namespace.
Variables are explicit; there is no ambient state leak between renders.

**Full rebuild on every build** — `build/` is cleaned before each run. Simplifies correctness guarantees: the output is
always a pure function of the current content. Incremental builds are a future concern (see TODO).

**Baron content compatibility** — filename convention (`YYYY-MM-DD-slug.md`), frontmatter schema, category inference
from subdirectories, and `<!--more-->` split marker intentionally match the Baron Blog Engine so existing content
migrates without modification.
