require_relative "../test_helper"

# Integration tests exercise the CLI class directly (not via subprocess),
# running against a real temporary site directory with real templates.
class CLITest < TikaTest
  include TestHelpers

  ARTICLE_BODY = <<~MD
    ---
    title: Hello World
    author: Test Author
    ---
    Welcome to the blog.

    <!--more-->

    More content here.
  MD

  ARTICLE_2_BODY = <<~MD
    ---
    title: Second Post
    ---
    Second article content.
  MD

  # ---------------------------------------------------------------------------
  # tika build
  # ---------------------------------------------------------------------------

  def test_build_command_succeeds
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert_includes last_output, "Built"
      assert_includes last_output, "1 article"
    end
  end

  def test_build_command_produces_valid_index
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert File.exist?("build/index.html")
      assert_includes File.read("build/index.html"), "Hello World"
    end
  end

  def test_build_command_produces_article_page
    in_site_dir(articles: { "2024-03-15-my-post.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert File.exist?("build/2024/03/15/my-post/index.html")
    end
  end

  def test_build_command_produces_category_page
    in_site_dir(articles: { "tech/2024-01-01-ruby.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert File.exist?("build/tech/index.html")
    end
  end

  def test_build_command_produces_archives
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert File.exist?("build/archives/index.html")
    end
  end

  def test_build_command_produces_feed
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert File.exist?("build/feed.atom")
      assert_includes File.read("build/feed.atom"), "Hello World"
    end
  end

  def test_build_command_produces_robots_txt
    in_site_dir do
      Tika::CLI.start(["build"])
      assert File.exist?("build/robots.txt")
    end
  end

  def test_build_command_with_multiple_articles
    in_site_dir(articles: {
      "2024-01-01-first.md"  => ARTICLE_BODY,
      "2024-06-15-second.md" => ARTICLE_2_BODY,
    }) do
      Tika::CLI.start(["build"])
      assert_includes last_output, "2 article"
    end
  end

  # ---------------------------------------------------------------------------
  # tika new
  # ---------------------------------------------------------------------------

  def test_new_command_creates_draft_file
    in_site_dir do
      Tika::CLI.start(["new", "My First Post"])
      today = Date.today.to_s
      expected = "content/drafts/#{today}-my-first-post.md"
      assert File.exist?(expected), "expected draft at #{expected}"
    end
  end

  def test_new_command_draft_contains_title_in_frontmatter
    in_site_dir do
      Tika::CLI.start(["new", "My First Post"])
      today = Date.today.to_s
      content = File.read("content/drafts/#{today}-my-first-post.md")
      assert_includes content, "title: My First Post"
    end
  end

  def test_new_command_draft_contains_author_from_config
    in_site_dir do
      Tika::CLI.start(["new", "Some Post"])
      today = Date.today.to_s
      content = File.read("content/drafts/#{today}-some-post.md")
      assert_includes content, "author: Test Author"
    end
  end

  def test_new_command_slug_normalizes_title
    in_site_dir do
      Tika::CLI.start(["new", "Hello, World! 2024"])
      today    = Date.today.to_s
      expected = "content/drafts/#{today}-hello-world-2024.md"
      assert File.exist?(expected), "slug should be normalized"
    end
  end

  def test_new_command_does_not_overwrite_existing_draft
    in_site_dir do
      Tika::CLI.start(["new", "Duplicate Post"])
      today = Date.today.to_s
      path  = "content/drafts/#{today}-duplicate-post.md"

      # Overwrite with different content to simulate a pre-existing draft
      File.write(path, "---\ntitle: Already there\n---\nExisting content.")

      Tika::CLI.start(["new", "Duplicate Post"])
      assert_includes last_output, "already exists"
      assert_equal "---\ntitle: Already there\n---\nExisting content.", File.read(path)
    end
  end

  # ---------------------------------------------------------------------------
  # tika test
  # ---------------------------------------------------------------------------

  def test_test_command_passes_on_clean_build
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      Tika::CLI.start(["test"])
      assert_includes last_output, "OK"
    end
  end

  def test_test_command_fails_when_build_dir_missing
    in_site_dir do
      # Do not build — verifies that `tika test` prints a helpful error and
      # exits when build/ doesn't exist. stdout is already captured by TikaTest.
      assert_raises(SystemExit) { Tika::CLI.start(["test"]) }
    end
  end

  def test_test_command_detects_broken_links
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      # Inject a broken link into the index
      html = File.read("build/index.html")
      File.write("build/index.html", html + '<a href="/ghost-page/">ghost</a>')

      assert_raises(SystemExit) { Tika::CLI.start(["test"]) }
    end
  end

  def test_test_command_ignores_external_links
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      # External links should not be flagged
      html = File.read("build/index.html")
      File.write("build/index.html", html + '<a href="https://example.com">ext</a>')

      Tika::CLI.start(["test"])
      assert_includes last_output, "OK"
    end
  end

  # ---------------------------------------------------------------------------
  # tika init
  # ---------------------------------------------------------------------------

  def test_init_command_creates_site_directory
    Dir.mktmpdir("tika-init-test-") do |tmpdir|
      original = Dir.pwd
      begin
        Dir.chdir(tmpdir)
        Tika::CLI.start(["init", "my-blog"])
        assert Dir.exist?("my-blog"), "site directory should be created"
        assert File.exist?("my-blog/config.yml"), "config.yml should be copied"
        assert Dir.exist?("my-blog/content/articles")
        assert Dir.exist?("my-blog/content/drafts")
        assert Dir.exist?("my-blog/themes")
        assert_includes last_output, "my-blog"
      ensure
        Dir.chdir(original)
      end
    end
  end

  def test_init_command_fails_if_directory_exists
    Dir.mktmpdir("tika-init-test-") do |tmpdir|
      original = Dir.pwd
      begin
        Dir.chdir(tmpdir)
        Dir.mkdir("already-here")
        assert_raises(SystemExit) { Tika::CLI.start(["init", "already-here"]) }
        assert_includes last_output, "already exists"
      ensure
        Dir.chdir(original)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # tika deploy
  # ---------------------------------------------------------------------------

  def test_deploy_command_requires_build_directory
    in_site_dir do
      # build/ does not exist — should exit with error
      assert_raises(SystemExit) { Tika::CLI.start(["deploy"]) }
      assert_includes last_output, "not found"
    end
  end

  def test_deploy_command_rsync_requires_dest
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert_raises(SystemExit) { Tika::CLI.start(["deploy", "--target", "rsync"]) }
      assert_includes last_output, "destination"
    end
  end

  def test_deploy_command_unknown_target_exits
    in_site_dir(articles: { "2024-01-01-hello.md" => ARTICLE_BODY }) do
      Tika::CLI.start(["build"])
      assert_raises(SystemExit) { Tika::CLI.start(["deploy", "--target", "ftp"]) }
      assert_includes last_output, "Unknown target"
    end
  end

  # ---------------------------------------------------------------------------
  # tika help / unknown command
  # ---------------------------------------------------------------------------

  def test_help_lists_commands
    Tika::CLI.start(["help"])
    assert_includes last_output, "build"
    assert_includes last_output, "new"
    assert_includes last_output, "test"
    assert_includes last_output, "deploy"
    assert_includes last_output, "serve"
  end

  def test_unknown_command_exits_with_error
    assert_raises(SystemExit) { Tika::CLI.start(["frobnicate"]) }
  end

  # ---------------------------------------------------------------------------
  # Full end-to-end: build → test flow
  # ---------------------------------------------------------------------------

  def test_full_build_and_test_workflow
    articles = {
      "2024-01-01-intro.md"         => ARTICLE_BODY,
      "cooking/2024-02-10-pasta.md" => ARTICLE_2_BODY,
    }
    pages = { "about.md" => "---\ntitle: About\n---\nAbout page." }

    in_site_dir(articles: articles, pages: pages) do
      Tika::CLI.start(["build"])
      assert_includes last_output, "2 article"
      assert_includes last_output, "1 page"

      # Verify structure
      assert File.exist?("build/index.html")
      assert File.exist?("build/2024/01/01/intro/index.html")
      assert File.exist?("build/cooking/index.html")
      assert File.exist?("build/about/index.html")
      assert File.exist?("build/archives/index.html")
      assert File.exist?("build/feed.atom")

      # Test (link validation)
      Tika::CLI.start(["test"])
      assert_includes last_output, "OK"

      # New draft
      Tika::CLI.start(["new", "Draft Article"])
      today = Date.today.to_s
      assert File.exist?("content/drafts/#{today}-draft-article.md")
    end
  end
end
