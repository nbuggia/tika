# Example Site

A sample blog built with [Tika](https://github.com/nbuggia/tika). Features Robert Frost poetry organized into categories, with an about page, Atom feed, and pagination.

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

## Writing a page

Create a file in `content/pages/` named `slug.md`:

```markdown
---
title: About
---

Page content here.
```

Pages appear in the site navigation automatically and are served at `/slug/`.

## Drafts

Create a file in `content/drafts/` using the same format. Drafts are not built — move the file into `content/articles/` when ready to publish.

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
