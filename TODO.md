# Tika — Backlog

## Correctness

- [ ] **Fix robots.txt sitemap reference** — `build_robots` hardcodes a `Sitemap:` line pointing to `sitemap.xml`, which is never generated. Either generate `sitemap.xml` or remove the reference.
- [ ] **Fix portable date format** — `%-d` in the default `date_format` is Linux/macOS only. `%e` is the POSIX-portable equivalent. Add a note to `config.yml` or change the default.
- [ ] **Verify blue and corporate themes** — Both were ported from Baron but never tested against Tika's ERB variable names (`@articles`, `@next_url`, `yield_content`, etc.). They likely have broken references. Either fix and test them or remove them.

## Missing Features

- [ ] **Generate sitemap.xml** — The builder already has all articles and pages needed. Generate a standard `sitemap.xml` alongside `robots.txt` and update `robots.txt` to reference it correctly.
- [ ] **Draft preview** — Files in `content/drafts/` are silently ignored by the builder. Add a `--drafts` flag to `tika build` and `tika serve` that includes drafts in the build so authors can preview before publishing.
- [ ] **Custom 404 page** — Add a `404.html.erb` template and have the builder generate a `404.html` in the build root. GitHub Pages, Netlify, and most static hosts pick this up automatically.

## Developer Experience

- [ ] **File watching in dev server** — `tika serve` rebuilds once on start then goes static. Add a watch loop on `content/` and `themes/` that triggers a rebuild on any change, making local development significantly smoother.
- [ ] **Better template error messages** — Template errors currently surface as raw Ruby backtraces with no indication of which template caused them. Wrap `Renderer#render_template` in a rescue that re-raises with the template path and line number included.

## Code Structure

- [ ] **Break up `Builder#build`** — The method loads content, renders 6 page types, copies assets, and writes files in one pass. Splitting into distinct loading, rendering, and writing phases would make the code easier to follow and open the door to incremental builds later.
- [ ] **Move feed generation out of themes** — `feed.xml.erb` is a theme template but Atom feeds are completely standard and themes have no reason to customize them. Moving feed generation into the builder as a built-in would reduce the template surface area every theme must implement.
- [ ] **Clarify `tika new` vs `tika init`** — `tika init` creates a new site, `tika new` creates a draft article. The relationship is slightly awkward when a user runs `tika new` outside a site directory and gets a `ConfigError` rather than a helpful suggestion to run `tika init` first.
