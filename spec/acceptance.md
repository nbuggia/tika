# Tika — Acceptance Criteria

Each criterion maps to a requirement in `spec/requirements.md`. Format: observable outcome verifiable manually or by an automated test.

## AC1 — Site initialization

| ID    | Req  | Criterion                                                                                                                                                |
| ----- | ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC1.1 | R1.1 | `tika init mysite` creates `mysite/` containing `config.yml`, `content/articles/`, `content/pages/`, `content/drafts/`, `content/images/`, `content/downloads/`, and `themes/` |
| AC1.2 | R1.2 | `mysite/config.yml` is valid YAML with all required keys present                                                                                         |
| AC1.3 | R1.3 | `tika init mysite` when `mysite/` already exists prints an error containing "already exists" and exits non-zero                                          |

## AC2 — Content authoring

| ID    | Req  | Criterion                                                                                                                                   |
| ----- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| AC2.1 | R2.1 | `tika new "Hello World"` creates `content/drafts/YYYY-MM-DD-hello-world.md` using today's date                                              |
| AC2.2 | R2.2 | The created file has a YAML frontmatter block with `title: Hello World` and `author:` matching `config.yml`                                 |
| AC2.3 | R2.3 | Running `tika build` does not produce any file under `build/` that corresponds to a file in `content/drafts/`                               |
| AC2.4 | R2.4 | Running `tika new "Hello World"` a second time on the same day prints "already exists" and leaves the original file byte-for-byte unchanged |
| AC2.5 | R2.2 | `tika new "Hello, World! 2024"` produces a slug containing only lowercase alphanumerics and hyphens (`hello-world-2024`)                    |

## AC3 — Site build

| ID     | Req   | Criterion                                                                                                                  |
| ------ | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| AC3.1  | R3.1  | After `tika build`, every `.md` file in `content/articles/` has a corresponding `index.html` somewhere under `build/`      |
| AC3.2  | R3.3  | An article at `content/articles/2024-03-15-my-post.md` produces `build/2024/03/15/my-post/index.html`                      |
| AC3.3  | R3.4  | An article at `content/articles/cooking/2024-01-01-pasta.md` appears in `build/cooking/index.html`                         |
| AC3.4  | R3.5  | With more articles than `posts_per_page`, `build/page/2/index.html` exists and its content differs from `build/index.html` |
| AC3.5  | R3.5  | `build/index.html` contains a link to `page/2/` when article count exceeds `posts_per_page`                                |
| AC3.6  | R3.6  | Each subdirectory name under `content/articles/` has a matching `build/<name>/index.html`                                  |
| AC3.7  | R3.7  | `build/archives/index.html` contains the title of every article in the site                                                |
| AC3.8  | R3.8  | `content/pages/about.md` produces `build/about/index.html` containing the page body                                        |
| AC3.9  | R3.9  | `build/feed.atom` is well-formed XML with an `<entry>` element for each article (up to `feed_entries`)                     |
| AC3.10 | R3.10 | `build/robots.txt` exists after a build                                                                                    |
| AC3.13 | R3.13 | Files in `content/downloads/` appear at identical relative paths under `build/downloads/` after a build                    |
| AC3.14 | R3.13 | If `content/downloads/` does not exist, `build/downloads/` is not created                                                  |
| AC3.11 | R3.2  | Running `tika build` twice in a row produces identical output (idempotent)                                                 |
| AC3.12 | R3.2  | Files present in `build/` from a previous build but no longer generated are removed                                        |

## AC4 — Theming

| ID    | Req  | Criterion                                                                                                          |
| ----- | ---- | ------------------------------------------------------------------------------------------------------------------ |
| AC4.1 | R4.2 | Files in `themes/default/static/` appear at identical relative paths under `build/static/` after a build           |
| AC4.2 | R4.3 | Setting `theme: blue` in `config.yml` causes the builder to load templates from `themes/blue/templates/`           |
| AC4.3 | R4.4 | A build with a missing required template (e.g. no `article.html.erb`) raises an error identifying the missing file |

## AC5 — Local preview

| ID    | Req  | Criterion                                                                                                    |
| ----- | ---- | ------------------------------------------------------------------------------------------------------------ |
| AC5.1 | R5.1 | `tika serve` starts a server; `curl http://localhost:4000/` returns HTTP 200 with the site title in the body |
| AC5.2 | R5.2 | `tika serve --port 8080` makes the site accessible at `http://localhost:8080/` and not at port 4000          |

## AC6 — Validation

| ID    | Req  | Criterion                                                                                                              |
| ----- | ---- | ---------------------------------------------------------------------------------------------------------------------- |
| AC6.1 | R6.1 | `tika test` after a clean `tika build` exits 0 and prints "All links OK"                                               |
| AC6.2 | R6.1 | `tika test` after injecting `<a href="/nonexistent/">` into a built HTML file exits non-zero and names the broken link |
| AC6.3 | R6.2 | `tika test` does not flag `href="https://example.com"` or `href="http://example.com"` as broken                        |
| AC6.4 | R6.3 | Running `tika test` when `build/` does not exist exits non-zero with a message containing "not found"                  |

## AC7 — Deployment

| ID    | Req  | Criterion                                                                                                 |
| ----- | ---- | --------------------------------------------------------------------------------------------------------- |
| AC7.1 | R7.1 | `tika deploy --target rsync --dest user@host:/path` invokes `rsync -avz --delete build/ user@host:/path`  |
| AC7.2 | R7.2 | `tika deploy --target ghpages` runs `git init`, `git add`, `git commit`, and `git push` against `build/`  |
| AC7.3 | R7.3 | `tika deploy` when `build/` does not exist exits non-zero with a message containing "not found"           |
| AC7.4 | R7.1 | `tika deploy --target rsync` without `--dest` exits non-zero with a message about providing a destination |
| AC7.5 | R7.1 | `tika deploy --target unknown` exits non-zero with a message naming the unknown target                    |

## AC8 — Configuration

| ID    | Req  | Criterion                                                                                                    |
| ----- | ---- | ------------------------------------------------------------------------------------------------------------ |
| AC8.1 | R8.1 | Running any `tika` command from a directory without `config.yml` raises a `ConfigError` with a clear message |
| AC8.2 | R8.4 | `@config["title"]` and `@config.title` both return the same value from `config.yml` in a template            |
| AC8.3 | R8.3 | A `config.yml` missing a required key (e.g. `base_url`) raises a `ConfigError` that names the missing key    |
