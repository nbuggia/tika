require_relative "../test_helper"

class RendererTest < TikaTest
  include TestHelpers

  def test_render_wraps_partial_in_layout
    in_site_dir do |dir|
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("home.html.erb", articles: [], pages: [], categories: {})
      assert_includes result, "<!DOCTYPE html>"
      assert_includes result, "<body>"
      assert_includes result, "</html>"
    end
  end

  def test_render_injects_config_into_layout
    in_site_dir do |dir|
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("home.html.erb", articles: [], pages: [], categories: {})
      assert_includes result, "Test Blog"
    end
  end

  def test_render_makes_locals_available_as_instance_vars
    in_site_dir do |dir|
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      page     = make_test_page(dir)
      result   = renderer.render("page.html.erb", page: page, pages: [], categories: {})
      assert_includes result, page.title
    end
  end

  def test_render_partial_skips_layout
    in_site_dir do |dir|
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render_partial("feed.xml.erb", articles: [], config: config)
      assert_includes result, "<?xml"
      refute_includes result, "<!DOCTYPE html>"
    end
  end

  def test_render_raises_for_missing_template
    in_site_dir do |dir|
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      assert_raises(RuntimeError) { renderer.render("nonexistent.html.erb") }
    end
  end

  def test_render_article_includes_title_and_body
    in_site_dir do |dir|
      article  = make_test_article(dir)
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("article.html.erb", article: article, pages: [], categories: {})
      assert_includes result, article.title
      assert_includes result, "Test content"
    end
  end

  def test_render_category_lists_articles
    in_site_dir do |dir|
      article  = make_test_article(dir)
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("category.html.erb",
                                  category: "cooking",
                                  articles: [article],
                                  pages: [],
                                  categories: {})
      assert_includes result, article.title
    end
  end

  def test_render_archives_lists_articles
    in_site_dir do |dir|
      article  = make_test_article(dir)
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("archives.html.erb",
                                  articles: [article],
                                  pages: [],
                                  categories: {})
      assert_includes result, article.title
    end
  end

  def test_render_home_shows_article_titles
    in_site_dir do |dir|
      article  = make_test_article(dir)
      config   = Tika::Config.load
      renderer = Tika::Renderer.new(config)
      result   = renderer.render("home.html.erb",
                                  articles: [article],
                                  pages: [],
                                  categories: {},
                                  page_num: 1,
                                  total_pages: 1,
                                  prev_url: nil,
                                  next_url: nil)
      assert_includes result, article.title
    end
  end

  private

  def make_test_article(dir)
    articles_dir = File.join(dir, "content", "articles")
    FileUtils.mkdir_p(articles_dir)
    path = File.join(articles_dir, "2024-01-15-test-article.md")
    File.write(path, "---\ntitle: Test Article\n---\nTest content.")
    config = Tika::Config.load
    config["content_dir"] = File.join(dir, "content")
    Tika::Models::Article.load(path, config)
  end

  def make_test_page(dir)
    pages_dir = File.join(dir, "content", "pages")
    FileUtils.mkdir_p(pages_dir)
    path = File.join(pages_dir, "about.md")
    File.write(path, "---\ntitle: About\n---\nAbout page.")
    config = Tika::Config.load
    Tika::Models::Page.new(path, config)
  end
end
