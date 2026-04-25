require_relative "../test_helper"

class BuilderTest < TikaTest
  include TestHelpers

  SAMPLE_ARTICLE = <<~MD
    ---
    title: Hello World
    author: Alice
    ---
    Welcome to my blog.

    <!--more-->

    More content here.
  MD

  SAMPLE_ARTICLE_2 = <<~MD
    ---
    title: Second Post
    ---
    Second post body.
  MD

  SAMPLE_PAGE = <<~MD
    ---
    title: About Me
    ---
    This is the about page.
  MD

  # ---------------------------------------------------------------------------
  # Build output structure
  # ---------------------------------------------------------------------------

  def test_build_returns_counts
    in_site_dir(articles: { "2024-01-01-hello.md" => SAMPLE_ARTICLE }) do
      config = Tika::Config.load
      stats  = Tika::Builder.new(config).build
      assert_equal 1, stats[:articles]
      assert_equal 0, stats[:pages]
    end
  end

  def test_build_creates_build_directory
    in_site_dir do
      config = Tika::Config.load
      Tika::Builder.new(config).build
      assert Dir.exist?("build"), "build/ dir should be created"
    end
  end

  def test_build_cleans_previous_output
    in_site_dir do
      FileUtils.mkdir_p("build/old-stuff")
      File.write("build/old-stuff/stale.html", "stale")
      config = Tika::Config.load
      Tika::Builder.new(config).build
      refute File.exist?("build/old-stuff/stale.html"), "stale files should be removed"
    end
  end

  def test_build_generates_index
    in_site_dir(articles: { "2024-01-01-hello.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/index.html"), "index.html should exist"
      html = File.read("build/index.html")
      assert_includes html, "Hello World"
    end
  end

  def test_build_generates_article_page
    in_site_dir(articles: { "2024-03-15-my-post.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/2024/03/15/my-post/index.html")
      html = File.read("build/2024/03/15/my-post/index.html")
      assert_includes html, "Hello World"
    end
  end

  def test_build_generates_archives
    in_site_dir(articles: { "2024-01-01-hello.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/archives/index.html")
      html = File.read("build/archives/index.html")
      assert_includes html, "Hello World"
    end
  end

  def test_build_generates_category_page
    in_site_dir(articles: { "cooking/2024-01-01-pasta.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/cooking/index.html")
      html = File.read("build/cooking/index.html")
      assert_includes html, "Hello World"
    end
  end

  def test_build_skips_category_page_for_root_articles
    in_site_dir(articles: { "2024-01-01-hello.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      # No category dir should be created for top-level articles
      refute File.exist?("build/articles"), "should not create /articles/ dir for root-level posts"
    end
  end

  def test_build_generates_custom_pages
    in_site_dir(
      articles: {},
      pages: { "about.md" => SAMPLE_PAGE }
    ) do
      stats = Tika::Builder.new(Tika::Config.load).build
      assert_equal 1, stats[:pages]
      assert File.exist?("build/about/index.html")
      html = File.read("build/about/index.html")
      assert_includes html, "About Me"
    end
  end

  def test_build_generates_feed
    in_site_dir(articles: { "2024-01-01-hello.md" => SAMPLE_ARTICLE }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/feed.atom")
      xml = File.read("build/feed.atom")
      assert_includes xml, "<?xml"
      assert_includes xml, "Hello World"
    end
  end

  def test_build_generates_robots_txt
    in_site_dir do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/robots.txt")
      assert_includes File.read("build/robots.txt"), "User-agent: *"
    end
  end

  def test_build_copies_theme_static_assets
    in_site_dir do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/static/css/style.css")
    end
  end

  def test_build_copies_content_images_when_present
    in_site_dir do
      FileUtils.mkdir_p("content/images")
      File.write("content/images/photo.png", "fake-png")
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/images/photo.png")
    end
  end

  def test_build_copies_downloads_when_present
    in_site_dir do
      FileUtils.mkdir_p("content/downloads")
      File.write("content/downloads/report.pdf", "fake-pdf")
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/downloads/report.pdf")
    end
  end

  def test_build_skips_downloads_when_absent
    in_site_dir do
      Tika::Builder.new(Tika::Config.load).build
      refute File.exist?("build/downloads"), "build/downloads should not be created when content/downloads is absent"
    end
  end

  # ---------------------------------------------------------------------------
  # Pagination
  # ---------------------------------------------------------------------------

  def test_pagination_creates_multiple_index_pages
    # posts_per_page is 2 in DEFAULT_CONFIG_YAML; create 3 articles
    articles = {
      "2024-01-01-post-a.md" => SAMPLE_ARTICLE,
      "2024-02-01-post-b.md" => SAMPLE_ARTICLE_2,
      "2024-03-01-post-c.md" => "---\ntitle: Third Post\n---\nThird.",
    }
    in_site_dir(articles: articles) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/index.html"),         "page 1 at root"
      assert File.exist?("build/page/2/index.html"),  "page 2 should exist"
      refute File.exist?("build/page/1/index.html"),  "page 1 should not be duplicated"
    end
  end

  def test_pagination_next_link_on_first_page
    articles = {
      "2024-01-01-post-a.md" => SAMPLE_ARTICLE,
      "2024-02-01-post-b.md" => SAMPLE_ARTICLE_2,
      "2024-03-01-post-c.md" => "---\ntitle: Third Post\n---\nThird.",
    }
    in_site_dir(articles: articles) do
      Tika::Builder.new(Tika::Config.load).build
      html = File.read("build/index.html")
      assert_includes html, "Older", "first page should have next/older link"
    end
  end

  def test_pagination_prev_link_on_second_page
    articles = {
      "2024-01-01-post-a.md" => SAMPLE_ARTICLE,
      "2024-02-01-post-b.md" => SAMPLE_ARTICLE_2,
      "2024-03-01-post-c.md" => "---\ntitle: Third Post\n---\nThird.",
    }
    in_site_dir(articles: articles) do
      Tika::Builder.new(Tika::Config.load).build
      html = File.read("build/page/2/index.html")
      assert_includes html, "Newer", "second page should have prev/newer link"
    end
  end

  # ---------------------------------------------------------------------------
  # Edge cases
  # ---------------------------------------------------------------------------

  def test_build_with_no_content
    in_site_dir do
      stats = Tika::Builder.new(Tika::Config.load).build
      assert_equal 0, stats[:articles]
      assert_equal 0, stats[:pages]
      assert File.exist?("build/index.html")
    end
  end

  def test_articles_sorted_newest_first
    articles = {
      "2023-01-01-older.md" => "---\ntitle: Older Post\n---\nOld.",
      "2024-06-01-newer.md" => "---\ntitle: Newer Post\n---\nNew.",
    }
    in_site_dir(articles: articles) do
      Tika::Builder.new(Tika::Config.load).build
      html = File.read("build/index.html")
      newer_pos = html.index("Newer Post")
      older_pos = html.index("Older Post")
      assert newer_pos < older_pos, "newer article should appear first"
    end
  end

  def test_build_with_txt_extension_articles
    in_site_dir(articles: { "2024-01-01-text-post.txt" => "---\ntitle: Text Post\n---\nContent." }) do
      Tika::Builder.new(Tika::Config.load).build
      assert File.exist?("build/2024/01/01/text-post/index.html")
    end
  end

  def test_custom_build_dir
    custom_yaml = TestHelpers::DEFAULT_CONFIG_YAML + "build_dir: \"output\"\n"
    in_site_dir(config_yaml: custom_yaml) do
      Tika::Builder.new(Tika::Config.load).build
      assert Dir.exist?("output"), "should use custom build_dir"
    end
  end
end
