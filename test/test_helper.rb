require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  minimum_coverage 80
end

require "minitest/autorun"
require "fileutils"
require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "tika"

# ---------------------------------------------------------------------------
# TikaTest — base class for all Tika tests
#
# Redirects $stdout before every test and restores it after. This keeps the
# test run output clean regardless of what CLI commands print. Tests that need
# to assert on output should call `last_output` after the command runs.
# ---------------------------------------------------------------------------
class TikaTest < Minitest::Test
  def setup
    # Redirect $stdout and $stderr so CLI output doesn't pollute the test run.
    # Tests that need to assert on output should call last_output / last_error
    # after the command runs.
    @_stdout_capture = StringIO.new
    @_stderr_capture = StringIO.new
    $stdout = @_stdout_capture
    $stderr = @_stderr_capture
  end

  def teardown
    $stdout = STDOUT
    $stderr = STDERR
  end

  # Returns everything printed to $stdout since setup.
  def last_output
    @_stdout_capture.string
  end

  # Returns everything printed to $stderr since setup.
  def last_error
    @_stderr_capture.string
  end
end

# ---------------------------------------------------------------------------
# Shared helpers available to all test classes
# ---------------------------------------------------------------------------
module TestHelpers
  FIXTURES_DIR = File.expand_path("fixtures", __dir__)

  DEFAULT_CONFIG_YAML = <<~YAML
    title:           "Test Blog"
    author:          "Test Author"
    description:     "A test blog"
    base_url:        "http://localhost:4000"
    theme:           "default"
    posts_per_page:  2
    feed_entries:    10
    permalink_style: "year_month_day"
    content_dir:     "content"
    build_dir:       "build"
  YAML

  # Minimal ERB templates used in unit tests (no CSS/JS deps)
  MINIMAL_TEMPLATES = {
    "layout.html.erb" => <<~ERB,
      <!DOCTYPE html>
      <html>
      <head><title><%= defined?(@page_title) ? @page_title.to_s + " | " + @config["title"] : @config["title"] %></title></head>
      <body>
      <nav>
        <% Array(@pages).each do |p| %><a href="<%= p.permalink %>"><%= p.title %></a><% end %>
      </nav>
      <%= yield_content %>
      </body></html>
    ERB
    "home.html.erb" => <<~ERB,
      <% @articles.each do |a| %>
      <article><h2><a href="<%= a.permalink %>"><%= a.title %></a></h2>
      <%= a.summary %>
      <% if a.has_more? %><a href="<%= a.permalink %>">Read more</a><% end %>
      </article>
      <% end %>
      <% next_url = defined?(@next_url) ? @next_url : nil %>
      <% prev_url = defined?(@prev_url) ? @prev_url : nil %>
      <% if next_url %><a class="next" href="<%= next_url %>">Older</a><% end %>
      <% if prev_url %><a class="prev" href="<%= prev_url %>">Newer</a><% end %>
    ERB
    "article.html.erb" => <<~ERB,
      <% @page_title = @article.title %>
      <article>
        <h1><%= @article.title %></h1>
        <p class="meta"><%= @article.date %> by <%= @article.author %></p>
        <div class="body"><%= @article.body %></div>
      </article>
    ERB
    "category.html.erb" => <<~ERB,
      <% @page_title = @category %>
      <h1><%= @category %></h1>
      <ul>
      <% @articles.each do |a| %><li><a href="<%= a.permalink %>"><%= a.title %></a></li><% end %>
      </ul>
    ERB
    "archives.html.erb" => <<~ERB,
      <% @page_title = "Archives" %>
      <h1>Archives</h1>
      <ul>
      <% @articles.each do |a| %><li><a href="<%= a.permalink %>"><%= a.title %></a></li><% end %>
      </ul>
    ERB
    "page.html.erb" => <<~ERB,
      <% @page_title = @page.title %>
      <h1><%= @page.title %></h1>
      <div><%= @page.body %></div>
    ERB
    "feed.xml.erb" => <<~ERB,
      <?xml version="1.0"?>
      <feed>
      <% @articles.each do |a| %>
      <entry><title><%= a.title %></title><link href="<%= @config["base_url"] %><%= a.permalink %>"/></entry>
      <% end %>
      </feed>
    ERB
  }.freeze

  # Run a block with CWD changed to a fresh temp directory. The directory is
  # populated with a minimal site structure before yielding.
  def in_site_dir(config_yaml: DEFAULT_CONFIG_YAML,
                   articles: {},
                   pages: {},
                   use_minimal_templates: true)
    Dir.mktmpdir("tika-test-") do |tmpdir|
      original_pwd = Dir.pwd
      begin
        Dir.chdir(tmpdir)

        File.write("config.yml", config_yaml)
        FileUtils.mkdir_p(%w[content/articles content/drafts content/pages])

        articles.each do |rel_path, body|
          dest = File.join("content/articles", rel_path)
          FileUtils.mkdir_p(File.dirname(dest))
          File.write(dest, body)
        end

        pages.each do |filename, body|
          File.write(File.join("content/pages", filename), body)
        end

        setup_theme(tmpdir, use_minimal_templates: use_minimal_templates)

        yield tmpdir
      ensure
        Dir.chdir(original_pwd)
      end
    end
  end

  def setup_theme(tmpdir, use_minimal_templates: true)
    tpl_dir    = File.join(tmpdir, "themes", "default", "templates")
    static_dir = File.join(tmpdir, "themes", "default", "static", "css")
    FileUtils.mkdir_p(tpl_dir)
    FileUtils.mkdir_p(static_dir)
    File.write(File.join(static_dir, "style.css"), "body{}")

    if use_minimal_templates
      MINIMAL_TEMPLATES.each do |name, content|
        File.write(File.join(tpl_dir, name), content)
      end
    else
      # Copy the real project templates
      src = File.expand_path("../assets/themes/default/templates", __dir__)
      FileUtils.cp_r(Dir.glob("#{src}/*"), tpl_dir)
    end
  end

  def config_from_yaml(yaml = DEFAULT_CONFIG_YAML)
    tmpfile = Tempfile.new(["tika-config", ".yml"])
    tmpfile.write(yaml)
    tmpfile.close
    Tika::Config.load(tmpfile.path)
  ensure
    tmpfile&.unlink
  end
end
