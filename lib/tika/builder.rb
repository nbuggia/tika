require "fileutils"
require_relative "config"
require_relative "renderer"
require_relative "models/article"
require_relative "models/page"

module Tika
  class Builder
    def initialize(config)
      @config   = config
      @renderer = Renderer.new(config)
      @out      = config["build_dir"]
    end

    def build
      articles   = load_articles
      pages      = load_pages
      categories = articles.group_by(&:category)
                           .reject { |k, _| k.nil? }
                           .transform_values { |v| v.sort_by { |a| a.date }.reverse }

      FileUtils.rm_rf(@out)
      FileUtils.mkdir_p(@out)

      build_home(articles, pages, categories)
      build_articles(articles, pages, categories)
      build_category_pages(pages, categories)
      build_archives(articles, pages, categories)
      build_custom_pages(pages, categories)
      build_feed(articles)
      build_robots
      copy_assets

      { articles: articles.size, pages: pages.size }
    end

    private

    # -------------------------------------------------------------------------
    # Content loading
    # -------------------------------------------------------------------------

    def load_articles
      dir = File.join(@config["content_dir"], "articles")
      return [] unless Dir.exist?(dir)
      exts = %w[md txt]
      files = exts.flat_map { |e| Dir.glob(File.join(dir, "**", "*.#{e}")) }
      articles = files.map { |f| Models::Article.load(f, @config) }.compact
      articles.sort_by { |a| a.date }.reverse
    end

    def load_pages
      dir = File.join(@config["content_dir"], "pages")
      return [] unless Dir.exist?(dir)
      exts = %w[md txt html.erb]
      files = exts.flat_map { |e| Dir.glob(File.join(dir, "*.#{e}")) }
      files.map { |f| Models::Page.new(f, @config) }
    end

    # -------------------------------------------------------------------------
    # Page builders
    # -------------------------------------------------------------------------

    def build_home(articles, pages, categories)
      ppp   = @config["posts_per_page"].to_i
      pages_of_articles = articles.each_slice(ppp).to_a
      pages_of_articles = [[]] if pages_of_articles.empty?

      pages_of_articles.each_with_index do |page_articles, i|
        page_num    = i + 1
        total_pages = pages_of_articles.size
        locals = {
          is_home:     i == 0,
          articles:    page_articles,
          pages:       pages,
          categories:  categories,
          page_num:    page_num,
          total_pages: total_pages,
          prev_url:    i > 0 ? (i == 1 ? "/" : "/page/#{i}/") : nil,
          next_url:    i < total_pages - 1 ? "/page/#{i + 2}/" : nil,
        }
        html = @renderer.render("home.html.erb", locals)
        path = i == 0 ? "index.html" : "page/#{page_num}/index.html"
        write(path, html)
      end
    end

    def build_articles(articles, pages, categories)
      articles.each do |article|
        locals = { article: article, articles: articles, pages: pages, categories: categories }
        html   = @renderer.render("article.html.erb", locals)
        write(article.output_path, html)
      end
    end

    def build_category_pages(pages, categories)
      categories.each do |category, cat_articles|
        locals = { category: category, articles: cat_articles, pages: pages, categories: categories }
        html   = @renderer.render("category.html.erb", locals)
        write("#{category}/index.html", html)
      end
    end

    def build_archives(articles, pages, categories)
      locals = { articles: articles, pages: pages, categories: categories }
      html   = @renderer.render("archives.html.erb", locals)
      write("archives/index.html", html)
    end

    def build_custom_pages(pages, categories)
      pages.each do |page|
        locals = { page: page, pages: pages, categories: categories }
        html   = @renderer.render("page.html.erb", locals)
        write(page.output_path, html)
      end
    end

    def build_feed(articles)
      feed_articles = articles.first(@config["feed_entries"].to_i)
      xml = @renderer.render_partial("feed.xml.erb", articles: feed_articles)
      write("feed.atom", xml)
    end

    def build_robots
      content = "User-agent: *\nAllow: /\nSitemap: #{@config["base_url"]}/sitemap.xml\n"
      write("robots.txt", content)
    end

    # -------------------------------------------------------------------------
    # Assets
    # -------------------------------------------------------------------------

    def copy_assets
      theme_static = File.join("themes", @config["theme"], "static")
      if Dir.exist?(theme_static)
        FileUtils.cp_r(Dir.glob("#{theme_static}/*"), File.join(@out, "static").tap { |d| FileUtils.mkdir_p(d) })
      end

      # Copy content/images if present
      images_dir = File.join(@config["content_dir"], "images")
      if Dir.exist?(images_dir)
        FileUtils.cp_r(images_dir, File.join(@out, "images"))
      end

      # Copy content/downloads if present
      downloads_dir = File.join(@config["content_dir"], "downloads")
      if Dir.exist?(downloads_dir)
        FileUtils.cp_r(downloads_dir, File.join(@out, "downloads"))
      end
    end

    # -------------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------------

    def write(rel_path, content)
      dest = File.join(@out, rel_path)
      FileUtils.mkdir_p(File.dirname(dest))
      File.write(dest, content)
    end
  end
end
