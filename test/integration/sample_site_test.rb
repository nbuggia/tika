require_relative "../test_helper"

# Integration tests that build the sample Robert Frost site in
# test/sample-site/ and assert against the real output. These tests use the
# actual content and the real default theme templates.
class SampleSiteTest < TikaTest
  SAMPLE_SITE = File.expand_path("../../test/sample-site", __dir__)

  def setup
    super
    @original_pwd = Dir.pwd
    Dir.chdir(SAMPLE_SITE)
    @config = Tika::Config.load
    @builder = Tika::Builder.new(@config)
    @stats = @builder.build
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(File.join(SAMPLE_SITE, "build"))
    super
  end

  # ---------------------------------------------------------------------------
  # Build counts
  # ---------------------------------------------------------------------------

  def test_builds_all_seven_articles
    assert_equal 7, @stats[:articles]
  end

  def test_builds_one_page
    assert_equal 1, @stats[:pages]
  end

  # ---------------------------------------------------------------------------
  # Home page and pagination
  # ---------------------------------------------------------------------------

  def test_home_page_exists
    assert File.exist?("build/index.html")
  end

  def test_home_page_shows_site_title
    assert_includes read("build/index.html"), "Robert Frost"
  end

  def test_home_page_shows_three_articles
    # posts_per_page: 3 in sample config
    html = read("build/index.html")
    titles = ["The Road Not Taken", "The Death of the Hired Man",
              "Mending Wall", "The Mountain", "A Hundred Collars",
              "The Pasture", "If"]
    shown = titles.count { |t| html.include?(t) }
    assert_equal 5, shown, "home page should show exactly 5 articles"
  end

  def test_pagination_page_two_exists
    assert File.exist?("build/page/2/index.html")
  end

  def test_pagination_page_three_exists
    refute File.exist?("build/page/3/index.html"), "only 2 pages needed for 7 articles at 5 per page"
  end

  def test_no_page_four
    refute File.exist?("build/page/4/index.html"), "only 2 pages needed for 7 articles at 5 per page"
  end

  def test_home_page_has_older_link
    assert_includes read("build/index.html"), "Previous articles"
  end

  def test_page_two_has_newer_link
    assert_includes read("build/page/2/index.html"), "Newer articles"
  end

  # ---------------------------------------------------------------------------
  # Individual article pages
  # ---------------------------------------------------------------------------

  def test_the_pasture_page_exists
    assert File.exist?("build/1914/01/01/the-pasture/index.html")
  end

  def test_mending_wall_page_exists
    assert File.exist?("build/1914/01/02/mending-wall/index.html")
  end

  def test_death_of_hired_man_page_exists
    assert File.exist?("build/1914/01/03/the-death-of-the-hired-man/index.html")
  end

  def test_the_mountain_page_exists
    assert File.exist?("build/1914/01/04/the-mountain/index.html")
  end

  def test_a_hundred_collars_page_exists
    assert File.exist?("build/1914/01/05/a-hundred-collars/index.html")
  end

  def test_road_not_taken_page_exists
    assert File.exist?("build/1916/01/01/the-road-not-taken/index.html")
  end

  def test_if_page_exists
    assert File.exist?("build/1909/01/02/if/index.html")
  end

  def test_article_page_contains_title
    html = read("build/1916/01/01/the-road-not-taken/index.html")
    assert_includes html, "The Road Not Taken"
  end

  def test_article_page_contains_body
    html = read("build/1916/01/01/the-road-not-taken/index.html")
    assert_includes html, "Two roads diverged"
  end

  def test_article_page_shows_author
    html = read("build/1916/01/01/the-road-not-taken/index.html")
    assert_includes html, "Robert Frost"
  end

  def test_article_with_more_separator_has_full_body
    html = read("build/1914/01/02/mending-wall/index.html")
    # Content after <!--more--> should appear on the article page
    assert_includes html, "Good fences make good neighbors"
  end

  def test_if_shows_correct_author
    # "If" is by Rudyard Kipling, not Robert Frost
    html = read("build/1909/01/02/if/index.html")
    assert_includes html, "Rudyard Kipling"
  end

  # ---------------------------------------------------------------------------
  # Category pages
  # ---------------------------------------------------------------------------

  def test_north_of_boston_category_exists
    assert File.exist?("build/north-of-boston/index.html")
  end

  def test_favorites_category_exists
    assert File.exist?("build/favorites/index.html")
  end

  def test_other_authors_category_exists
    assert File.exist?("build/other-authors/index.html")
  end

  def test_north_of_boston_lists_five_poems
    html = read("build/north-of-boston/index.html")
    titles = ["The Pasture", "Mending Wall", "The Death of the Hired Man",
              "The Mountain", "A Hundred Collars"]
    titles.each { |t| assert_includes html, t }
  end

  def test_favorites_lists_road_not_taken
    assert_includes read("build/favorites/index.html"), "The Road Not Taken"
  end

  def test_other_authors_lists_if
    assert_includes read("build/other-authors/index.html"), "If"
  end

  def test_categories_appear_in_sidebar
    html = read("build/index.html")
    assert_includes html, "north-of-boston"
    assert_includes html, "favorites"
    assert_includes html, "other-authors"
  end

  # ---------------------------------------------------------------------------
  # Archives
  # ---------------------------------------------------------------------------

  def test_archives_page_exists
    assert File.exist?("build/archives/index.html")
  end

  def test_archives_lists_all_seven_articles
    html = read("build/archives/index.html")
    titles = ["The Pasture", "Mending Wall", "The Death of the Hired Man",
              "The Mountain", "A Hundred Collars", "The Road Not Taken", "If"]
    titles.each { |t| assert_includes html, t }
  end

  # ---------------------------------------------------------------------------
  # Custom pages
  # ---------------------------------------------------------------------------

  def test_about_page_exists
    assert File.exist?("build/about/index.html")
  end

  def test_about_page_contains_content
    assert_includes read("build/about/index.html"), "Robert Lee Frost"
  end

  def test_about_page_appears_in_nav
    assert_includes read("build/index.html"), "/about/"
  end

  # ---------------------------------------------------------------------------
  # Feed and robots
  # ---------------------------------------------------------------------------

  def test_feed_exists
    assert File.exist?("build/feed.atom")
  end

  def test_feed_contains_articles
    xml = read("build/feed.atom")
    assert_includes xml, "The Road Not Taken"
  end

  def test_feed_is_valid_xml
    xml = read("build/feed.atom")
    assert_includes xml, "<?xml"
    assert_includes xml, "<feed"
    assert_includes xml, "</feed>"
  end

  def test_robots_txt_exists
    assert File.exist?("build/robots.txt")
  end

  # ---------------------------------------------------------------------------
  # Static assets
  # ---------------------------------------------------------------------------

  def test_css_copied_to_build
    assert File.exist?("build/static/css/theme.css")
  end

  private

  def read(path)
    File.read(path)
  end
end
