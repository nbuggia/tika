# Example Site

A sample blog built with [Tika](https://github.com/nbuggia/tika). Features sample content organized into categories,
with an about page, Atom feed, and pagination.

## Structure

```text
config.yml              # site configuration
content/
  articles/             # blog posts (YYYY-MM-DD-slug.md or .txt)
    favorites/          # category: favorites
    north-of-boston/    # category: north-of-boston
    other-authors/      # category: other-authors
  pages/
    about.md            # becomes /about/
themes/
  default/              # ERB templates and CSS
build/                  # generated output (created on build, not committed)
```

## Writing an article

Create a file in `content/articles/` named `YYYY-MM-DD-your-title.md`:

```markdown
---
title: My Article Title
author: Your Name
---

Opening paragraph shown as the summary on the home page.

<!--more-->

The rest of the article, only shown on the article page.
```

To place an article in a category, put it in a subdirectory:

```text
content/articles/cooking/2024-03-01-pasta-recipe.md
```

The directory name becomes the category (e.g. `cooking`).

## Creating a custom page

Create a file in `content/pages/` named `slug.md`. You can include any markdown, HTML or javascript within the page.
The rendering template for the custom page is located `themes/my-theme/templates/page.html.erb`

```markdown
---
title: About
---

Page content here.
```

Pages appear in the site navigation automatically and are served at `/slug/`.

## Drafts

Create a file in `content/drafts/` using the same format. Drafts are not built — move the file into `content/articles/`
when ready to publish.

## Configuration

Edit `config.yml`:

```yaml
title: "My Blog"
author: "Your Name"
description: "A personal blog"
base_url: "https://example.com"
theme: "default"
posts_per_page: 10
feed_entries: 20
permalink_style: "year_month_day" # year_month_day | year_month | flat


# Optional
# twitter:              "yourhandle"
# disqus_shortname:     "yoursite"
# google_analytics_id:  "G-XXXXXXXXXX"
```

### Permalink styles

| Style            | Example URL            |
| ---------------- | ---------------------- |
| `year_month_day` | `/2024/01/15/my-post/` |
| `year_month`     | `/2024/01/my-post/`    |
| `flat`           | `/my-post/`            |

## Creating a custom theme

Themes live in `themes/<name>/` in the root folder of your site. Set `theme: "<name>"` in `config.yml` to activate one.

### Directory structure

```text
themes/
  my-theme/
    templates/          # ERB templates (all required)
      layout.html.erb
      home.html.erb
      article.html.erb
      category.html.erb
      archives.html.erb
      page.html.erb
      feed.xml.erb
    static/             # copied verbatim into build/static/
      css/
      js/
```

### How layout and templates interact

`layout.html.erb` is the outer shell (nav, header, footer). Call `<%= yield_content %>` where the page body should
appear. Every other template renders as the inner content inserted at that point.

### Template variables

Each template receives `@config` (all values from `config.yml`) plus page-specific variables:

| Template            | Variables available                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------------------- |
| `layout.html.erb`   | `@config`, `@pages`, `@categories`, `@is_home`                                                          |
| `home.html.erb`     | `@articles`, `@pages`, `@categories`, `@is_home`, `@page_num`, `@total_pages`, `@prev_url`, `@next_url` |
| `article.html.erb`  | `@article`, `@articles`, `@pages`, `@categories`                                                        |
| `category.html.erb` | `@category` (string), `@articles`, `@pages`, `@categories`                                              |
| `archives.html.erb` | `@articles`, `@pages`, `@categories`                                                                    |
| `page.html.erb`     | `@page`, `@pages`, `@categories`                                                                        |
| `feed.xml.erb`      | `@articles`                                                                                             |

Key object attributes:

- **`@article` / items in `@articles`** — `.title`, `.author`, `.date`, `.formatted_date`, `.slug`, `.permalink`,
  `.summary`, `.body`, `.category`, `.has_more?`
- **`@page` / items in `@pages`** — `.title`, `.body`, `.permalink`
- **`@categories`** — hash of `{ category_name => [articles] }`

### Static assets

Files under `themes/<name>/static/` are copied to `build/static/` at build time. Reference them in templates as
`/static/css/theme.css`, etc.

### Starting from an existing theme

Copy `assets/themes/default/` from the Tika repository as a starting point, rename the directory, then update
`config.yml`:

```yaml
theme: "my-theme"
```

## Local development

Build the site:

```sh
tika build
```

Preview locally at `http://localhost:4000`:

```sh
tika serve
```

Check for broken internal links:

```sh
tika test
```

## Deploying

Via rsync:

```sh
tika deploy --target rsync --dest user@host:/var/www/html
```

Via GitHub Pages:

```sh
tika deploy --target ghpages
```
