# Tika

A static site generator for Ruby. Successor to [Baron Blog Engine](https://github.com/nbuggia/baron-blog-engine-gem).

## Quick Start

### Install dependencies

```sh
bundle install
```

### Run the tests (also builds the example site)

```sh
bundle exec rake test
```

Tests provision a fresh copy of `assets/example-site/` into `test/sample-site/`, run all unit and integration tests, and report coverage to `coverage/`.

### Preview the example site locally

```sh
bundle exec rake serve
```

Opens the example site at `http://localhost:4000`. Rebuilds from source before serving.

### Create a new site

```sh
tika init my-blog
cd my-blog
tika build
tika serve
```

`tika init` scaffolds the directory, copies the default theme, and writes a starter `config.yml`. Edit it, add content to `content/articles/`, then `tika build` to generate `build/`.

---

### Gem workflow

**Build the gem locally:**

```sh
gem build tika.gemspec
# → tika-0.1.0.gem
```

**Install locally for testing:**

```sh
gem install tika-0.1.0.gem
```

**Release to RubyGems** (runs the full test suite first):

```sh
bundle exec rake release
```

Requires RubyGems credentials at `~/.gem/credentials`. Bumping the version first:

```sh
# Edit tika.gemspec: s.version = "0.x.y"
bundle exec rake release
```

**Install the published gem:**

```sh
gem install tika
```

---

## Project structure

```text
bin/                        # CLI executable (shipped with gem)
lib/tika/                   # gem library code
  config.rb                 # configuration loader
  models/article.rb         # article model
  models/page.rb            # page model
  renderer.rb               # ERB template renderer
  builder.rb                # static site builder
  server.rb                 # local dev server (WEBrick)
  cli.rb                    # CLI commands (OptionParser)
assets/
  themes/default/           # default theme (shipped with gem)
  example-site/             # sample site used as test fixture
test/
  unit/                     # unit tests (Config, Article, Page, Renderer, Builder)
  integration/              # integration tests (CLI, sample site end-to-end)
  sample-site/              # provisioned copy of example-site (ephemeral, gitignored)
```

## Dependencies

Runtime:

| Gem                                        | Purpose                        |
| ------------------------------------------ | ------------------------------ |
| [kramdown](https://kramdown.gettalong.org) | Markdown rendering (pure Ruby) |

Development:

| Gem       | Purpose        |
| --------- | -------------- |
| minitest  | Test framework |
| simplecov | Code coverage  |
| rake      | Task runner    |

## Setup

Install dependencies:

```sh
bundle install
```

If using the system Ruby on macOS (2.6), gems can't be installed globally without sudo. Install to your user directory instead:

```sh
GEM_HOME=$HOME/.gem/ruby/2.6.0 GEM_PATH=$HOME/.gem/ruby/2.6.0 bundle install
```

Add to `~/.zshrc` to avoid repeating the env vars:

```sh
export GEM_HOME=$HOME/.gem/ruby/2.6.0
export GEM_PATH=$HOME/.gem/ruby/2.6.0
```

## Running tests

```sh
bundle exec rake test
```

This provisions a fresh copy of `assets/example-site/` into `test/sample-site/`, then runs all unit and integration tests. Coverage is written to `coverage/` after each run.

To run a single test file:

```sh
bundle exec ruby -Ilib:test test/unit/article_test.rb
```

## Rake tasks

| Task             | Description                                                         |
| ---------------- | ------------------------------------------------------------------- |
| `rake test`      | Provision sample site and run all tests                             |
| `rake provision` | Copy `assets/example-site/` to `test/sample-site/`                  |
| `rake serve`     | Provision and serve the sample site at `http://localhost:4000`      |
| `rake clean`     | Remove `test/sample-site/`, `coverage/`, and any built `.gem` files |
| `rake release`   | Run tests, build the gem, and push to RubyGems                      |

## How it works

### Logic flow

A `tika build` call follows this sequence:

```text
CLI#build
  └─ Config.load            # reads config.yml into a Hash subclass
  └─ Builder#build
       ├─ load_articles      # parses content/articles/**/*.md → Array<Article>
       ├─ load_pages         # parses content/pages/*.md       → Array<Page>
       ├─ group categories   # articles grouped by subdirectory name
       │
       ├─ build_home         # renders home.html.erb (paginated) → build/index.html
       ├─ build_articles     # renders article.html.erb per article → build/YYYY/MM/DD/slug/index.html
       ├─ build_category_pages  # renders category.html.erb per category → build/<category>/index.html
       ├─ build_archives     # renders archives.html.erb → build/archives/index.html
       ├─ build_custom_pages # renders page.html.erb per page → build/<slug>/index.html
       ├─ build_feed         # renders feed.xml.erb → build/feed.atom
       ├─ build_robots       # writes static robots.txt
       └─ copy_assets        # copies themes/<name>/static/ → build/static/
                             # copies content/images/ → build/images/
```

Each render call goes through `Renderer#render`, which:

1. Creates a `RenderContext` and sets all locals as instance variables (`@article`, `@articles`, etc.)
2. Renders the partial template (e.g. `article.html.erb`) against that context
3. Renders `layout.html.erb` against the same context, calling `yield_content` to insert the partial output

### Article data structure

Articles are parsed from files named `YYYY-MM-DD-slug.md` (or `.txt`) inside `content/articles/`. Files in a subdirectory are automatically assigned to that category (e.g. `content/articles/north-of-boston/` → category `"north-of-boston"`).

Each file has a YAML frontmatter block followed by Markdown body:

```markdown
---
title: Mending Wall
author: Robert Frost
---
Something there is that doesn't love a wall...

<!--more-->

He only says, 'Good fences make good neighbors.'
```

The `Article` object exposes:

| Attribute   | Source                                                    |
| ----------- | --------------------------------------------------------- |
| `title`     | frontmatter `title:`, falls back to slug                  |
| `author`    | frontmatter `author:`, falls back to `config.author`      |
| `date`      | filename prefix `YYYY-MM-DD`                              |
| `slug`      | filename suffix after the date                            |
| `category`  | frontmatter `category:`, falls back to subdirectory name  |
| `body`      | full Markdown body rendered to HTML                       |
| `summary`   | content before `<!--more-->`, or first paragraph          |
| `has_more?` | true if `<!--more-->` is present                          |
| `permalink` | URL path derived from `permalink_style` in config         |

All frontmatter keys are automatically available as methods on the article object. A custom key like `image: /images/foo.png` in frontmatter is accessible in templates as `@article.image`. Keys are normalized to lowercase.

### How templates access data

`Renderer` converts every key in the `locals` hash into an instance variable on the `RenderContext` before rendering. So a locals hash of:

```ruby
{ article: article, pages: pages, categories: categories }
```

becomes `@article`, `@pages`, and `@categories` inside the ERB template. `@config` is always set from the loaded `Config` object. There is no explicit allowlist — any key passed in `locals` by `Builder` is available in the template.

## Adding a new theme

Themes live in `assets/themes/<theme-name>/` and contain two directories:

```text
assets/themes/my-theme/
  templates/              # ERB templates
    layout.html.erb       # outer HTML shell, calls yield_content
    home.html.erb         # article list with pagination
    article.html.erb      # single article
    category.html.erb     # articles filtered by category
    archives.html.erb     # all articles chronologically
    page.html.erb         # custom pages (about, etc.)
    feed.xml.erb          # Atom feed
  static/                 # copied verbatim to build/static/
    css/
    js/
```

Templates are ERB. The following instance variables are available in all templates:

| Variable      | Type             | Description                   |
| ------------- | ---------------- | ----------------------------- |
| `@config`     | `Config`         | full site configuration       |
| `@articles`   | `Array<Article>` | articles for the current page |
| `@pages`      | `Array<Page>`    | all custom pages (for nav)    |
| `@categories` | `Hash`           | category name → articles      |

`layout.html.erb` calls `yield_content` to insert the rendered partial.

## Releasing a new version

1. Bump `s.version` in `tika.gemspec`
2. Run `bundle exec rake release`

This runs the full test suite, builds the gem, and pushes it to RubyGems. Requires RubyGems credentials at `~/.gem/credentials`.
