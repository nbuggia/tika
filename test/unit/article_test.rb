require_relative "../test_helper"

class ArticleTest < TikaTest
  include TestHelpers

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def make_config(overrides = {})
    config = Tika::Config.new
    config["title"]           = "Test Blog"
    config["author"]          = "Anonymous"
    config["theme"]           = "default"
    config["permalink_style"] = "year_month_day"
    config["permalink_prefix"] = ""
    config["date_format"]     = "%B %-d, %Y"
    config["content_dir"]     = "content"
    config["build_dir"]       = "build"
    overrides.each { |k, v| config[k] = v }
    config
  end

  def make_article(filename:, body:, subdir: nil, config_overrides: {})
    Dir.mktmpdir do |dir|
      articles_dir = subdir ? File.join(dir, "content", "articles", subdir) : File.join(dir, "content", "articles")
      FileUtils.mkdir_p(articles_dir)
      path = File.join(articles_dir, filename)
      File.write(path, body)

      config = make_config(config_overrides.merge("content_dir" => File.join(dir, "content")))
      article = Tika::Models::Article.load(path, config)
      yield article
    end
  end

  # ---------------------------------------------------------------------------
  # Filename parsing
  # ---------------------------------------------------------------------------

  def test_parses_date_and_slug_from_filename
    make_article(filename: "2024-03-15-my-post.md", body: "") do |a|
      assert_equal Date.new(2024, 3, 15), a.date
      assert_equal "my-post",             a.slug
    end
  end

  def test_returns_nil_for_invalid_filename
    Dir.mktmpdir do |dir|
      path = File.join(dir, "no-date-here.md")
      File.write(path, "")
      config = make_config("content_dir" => dir)
      assert_nil Tika::Models::Article.load(path, config)
    end
  end

  def test_accepts_txt_extension
    make_article(filename: "2023-06-01-old-post.txt", body: "Hello") do |a|
      assert_equal "old-post", a.slug
    end
  end

  # ---------------------------------------------------------------------------
  # Frontmatter
  # ---------------------------------------------------------------------------

  def test_uses_frontmatter_title
    body = "---\ntitle: Custom Title\n---\nBody here."
    make_article(filename: "2024-01-01-my-post.md", body: body) do |a|
      assert_equal "Custom Title", a.title
    end
  end

  def test_uses_capitalized_title_key
    body = "---\nTitle: Baron Style\n---\nBody."
    make_article(filename: "2024-01-01-my-post.md", body: body) do |a|
      assert_equal "Baron Style", a.title
    end
  end

  def test_falls_back_to_humanized_slug_for_title
    make_article(filename: "2024-01-01-my-post.md", body: "") do |a|
      assert_equal "My Post", a.title
    end
  end

  def test_uses_frontmatter_author
    body = "---\nauthor: Alice\n---\nBody."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert_equal "Alice", a.author
    end
  end

  def test_falls_back_to_config_author
    make_article(filename: "2024-01-01-post.md", body: "No frontmatter") do |a|
      assert_equal "Anonymous", a.author
    end
  end

  def test_custom_frontmatter_key_accessible
    body = "---\ntitle: Post\nimage: /images/foo.png\n---\nBody."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert_equal "/images/foo.png", a.image
    end
  end

  # ---------------------------------------------------------------------------
  # Category
  # ---------------------------------------------------------------------------

  def test_infers_category_from_subdirectory
    make_article(filename: "2024-01-01-recipe.md", body: "", subdir: "cooking") do |a|
      assert_equal "cooking", a.category
    end
  end

  def test_category_is_nil_for_top_level_articles
    make_article(filename: "2024-01-01-post.md", body: "") do |a|
      assert_nil a.category
    end
  end

  # ---------------------------------------------------------------------------
  # Permalink styles
  # ---------------------------------------------------------------------------

  def test_permalink_year_month_day
    make_article(filename: "2024-03-15-hello.md", body: "") do |a|
      assert_equal "/2024/03/15/hello/", a.permalink
    end
  end

  def test_permalink_year_month
    make_article(filename: "2024-03-15-hello.md", body: "",
                 config_overrides: { "permalink_style" => "year_month" }) do |a|
      assert_equal "/2024/03/hello/", a.permalink
    end
  end

  def test_permalink_flat
    make_article(filename: "2024-03-15-hello.md", body: "",
                 config_overrides: { "permalink_style" => "flat" }) do |a|
      assert_equal "/hello/", a.permalink
    end
  end

  def test_permalink_with_prefix
    make_article(filename: "2024-03-15-hello.md", body: "",
                 config_overrides: { "permalink_prefix" => "blog" }) do |a|
      assert_equal "/blog/2024/03/15/hello/", a.permalink
    end
  end

  def test_output_path_matches_permalink
    make_article(filename: "2024-03-15-hello.md", body: "") do |a|
      assert_equal "2024/03/15/hello/index.html", a.output_path
    end
  end

  # ---------------------------------------------------------------------------
  # Body and summary
  # ---------------------------------------------------------------------------

  def test_body_renders_markdown
    make_article(filename: "2024-01-01-post.md", body: "# Hello\n\nWorld.") do |a|
      assert_match(/<h1[ >]/, a.body)
      assert_includes a.body, "Hello"
      assert_includes a.body, "<p>World.</p>"
    end
  end

  def test_summary_split_on_more_separator
    body = "Intro paragraph.\n\n<!--more-->\n\nRest of post."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert_includes a.summary, "Intro"
      refute_includes a.summary, "Rest of post"
    end
  end

  def test_summary_falls_back_to_first_paragraph
    body = "First paragraph.\n\nSecond paragraph."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert_includes a.summary, "First paragraph"
      refute_includes a.summary, "Second paragraph"
    end
  end

  def test_has_more_true_when_separator_present
    body = "Intro.\n\n<!--more-->\n\nRest."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert a.has_more?
    end
  end

  def test_has_more_false_when_no_separator
    make_article(filename: "2024-01-01-post.md", body: "Just text.") do |a|
      refute a.has_more?
    end
  end

  def test_more_separator_is_case_insensitive
    body = "Intro.\n\n<!-- MORE -->\n\nRest."
    make_article(filename: "2024-01-01-post.md", body: body) do |a|
      assert a.has_more?
    end
  end
end
