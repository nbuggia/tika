require_relative "../test_helper"

class PageTest < TikaTest
  include TestHelpers

  def make_config
    config = Tika::Config.new
    config["title"]       = "Test Blog"
    config["theme"]       = "default"
    config["content_dir"] = "content"
    config["build_dir"]   = "build"
    config
  end

  def make_page(filename:, body:)
    Dir.mktmpdir do |dir|
      path = File.join(dir, filename)
      File.write(path, body)
      page = Tika::Models::Page.new(path, make_config)
      yield page
    end
  end

  def test_slug_from_filename
    make_page(filename: "about.md", body: "") do |p|
      assert_equal "about", p.slug
    end
  end

  def test_title_from_frontmatter
    make_page(filename: "about.md", body: "---\ntitle: About Me\n---\nContent.") do |p|
      assert_equal "About Me", p.title
    end
  end

  def test_title_capitalized_key
    make_page(filename: "about.md", body: "---\nTitle: About\n---\nContent.") do |p|
      assert_equal "About", p.title
    end
  end

  def test_title_fallback_to_humanized_slug
    make_page(filename: "my-page.md", body: "No frontmatter.") do |p|
      assert_equal "My Page", p.title
    end
  end

  def test_permalink
    make_page(filename: "about.md", body: "") do |p|
      assert_equal "/about/", p.permalink
    end
  end

  def test_output_path
    make_page(filename: "about.md", body: "") do |p|
      assert_equal "about/index.html", p.output_path
    end
  end

  def test_body_renders_markdown
    make_page(filename: "about.md", body: "# Hello\n\nParagraph.") do |p|
      assert_match(/<h1[ >]/, p.body)
      assert_includes p.body, "Hello"
    end
  end

  def test_body_without_frontmatter
    make_page(filename: "simple.md", body: "Just text.") do |p|
      assert_includes p.body, "Just text"
    end
  end

  def test_path_stored
    Dir.mktmpdir do |dir|
      path = File.join(dir, "about.md")
      File.write(path, "")
      page = Tika::Models::Page.new(path, make_config)
      assert_equal path, page.path
    end
  end
end
