# Tika — Requirements

Tika is a command-line static site generator for personal blogs. It converts Markdown content files and ERB templates
into a deployable static HTML site.

## User

One user type: the **site owner** — a developer who authors content locally and publishes to a static host (GitHub
Pages, Netlify, rsync target).

## Functional Requirements

### R1 — Site initialization

- R1.1: User can create a new site skeleton with `tika init [name]`
- R1.2: The skeleton includes a default `config.yml`, empty content directories, and the default theme
- R1.3: Attempting to init into an existing directory must fail with a clear error

### R2 — Content authoring

- R2.1: User can create a new draft article with `tika new [title]`
- R2.2: Draft filenames are auto-generated as `YYYY-MM-DD-slug.md` using today's date and a normalized slug
- R2.3: Drafts live in `content/drafts/` and are not included in builds by default
- R2.4: Creating a draft when one with the same slug already exists must warn and not overwrite
- R2.5 `[planned]`: User can preview drafts with `tika build --drafts` or `tika serve --drafts`

### R3 — Site build

- R3.1: `tika build` reads all articles from `content/articles/` and pages from `content/pages/`
- R3.2: `build/` is cleaned before each build; output is always a full rebuild
- R3.3: Articles are rendered to `build/YYYY/MM/DD/slug/index.html`
- R3.4: Articles in a subdirectory (e.g. `content/articles/cooking/`) are assigned to that category
- R3.5: The home page is paginated: `build/index.html`, `build/page/2/index.html`, etc.
- R3.6: Each category gets a listing page at `build/<category>/index.html`
- R3.7: An archives page lists all articles at `build/archives/index.html`
- R3.8: Custom pages are rendered to `build/<slug>/index.html`
- R3.9: An Atom feed is generated at `build/feed.atom`
- R3.10: A `robots.txt` is generated at `build/robots.txt`
- R3.13: If `content/downloads/` exists, its contents are copied verbatim to `build/downloads/`
- R3.11 `[planned]`: A `sitemap.xml` is generated at `build/sitemap.xml` and referenced in `robots.txt`
- R3.12 `[planned]`: A `404.html` is generated from a `404.html.erb` theme template

### R4 — Theming

- R4.1: Templates are ERB files in `themes/<name>/templates/`
- R4.2: Static assets in `themes/<name>/static/` are copied verbatim to `build/static/`
- R4.3: Users switch themes by changing `theme:` in `config.yml`
- R4.4: Required templates per theme: `layout.html.erb`, `home.html.erb`, `article.html.erb`, `category.html.erb`,
  `archives.html.erb`, `page.html.erb`, `feed.xml.erb`
- R4.5 `[planned]`: Optional `404.html.erb` for a custom error page

### R5 — Local preview

- R5.1: `tika serve` builds the site and serves it at `http://localhost:4000`
- R5.2: Port is configurable with `--port` / `-p`
- R5.3 `[planned]`: File changes in `content/` or `themes/` trigger an automatic rebuild without restarting the server

### R6 — Validation

- R6.1: `tika test` scans all HTML files in `build/` for broken internal links
- R6.2: External links (`http://`, `https://`) are not checked
- R6.3: Exit code is 0 on success, non-zero if any broken links are found

### R7 — Deployment

- R7.1: `tika deploy --target rsync --dest user@host:/path` deploys via rsync
- R7.2: `tika deploy --target ghpages` pushes `build/` to a `gh-pages` branch
- R7.3: Deployment fails with a clear error if `build/` does not exist

### R8 — Configuration

- R8.1: Site configuration lives in `config.yml` at the site root
- R8.2: Required keys: `title`, `author`, `base_url`, `theme`, `content_dir`, `build_dir`
- R8.3: Missing required keys raise a `ConfigError` naming the missing key
- R8.4: All config values are accessible in templates via `@config["key"]` and `@config.key`

## Constraints

- Ruby >= 2.6; no additional runtime dependencies beyond `kramdown`
- Content format must remain compatible with Baron Blog Engine
- Output must be a directory of static files — no server-side runtime required
