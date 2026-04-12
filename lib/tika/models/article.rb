require "date"
require "yaml"
require "kramdown"

module Tika
  module Models
    # Adapted from Baron's Article model. Same file-naming convention:
    #   YYYY-MM-DD-slug.md  (or .txt)
    # Same YAML frontmatter: Title, Author, etc.
    class Article
      FILENAME_RE = /\A(\d{4}-\d{2}-\d{2})-(.+)\z/

      attr_reader :path, :date, :slug, :category, :title, :author, :raw_body, :front

      def initialize(path, config)
        @path   = path
        @config = config
        parse_filename!
        parse_content!
      end

      # Returns nil if filename doesn't match the expected pattern
      def self.load(path, config)
        stem = File.basename(path, ".*")
        return nil unless FILENAME_RE.match?(stem)
        new(path, config)
      end

      def permalink
        prefix = @config["permalink_prefix"].to_s.sub(%r{\A/}, "").sub(%r{/\z}, "")
        path = case @config["permalink_style"]
        when "flat"
          "/#{slug}/"
        when "year_month"
          "/#{date.strftime("%Y/%m")}/#{slug}/"
        else # year_month_day
          "/#{date.strftime("%Y/%m/%d")}/#{slug}/"
        end
        prefix.empty? ? path : "/#{prefix}#{path}"
      end

      def formatted_date
        @date.strftime(@config["date_format"] || "%B %-d, %Y")
      end

      def body
        Kramdown::Document.new(@raw_body).to_html
      end

      def summary
        # Content before <!--more-->, or first paragraph
        if @raw_body =~ /<!--\s*more\s*-->/i
          Kramdown::Document.new($`.strip).to_html
        else
          first_para = @raw_body.strip.split(/\n\n/).first.to_s
          Kramdown::Document.new(first_para).to_html
        end
      end

      def has_more?
        @raw_body =~ /<!--\s*more\s*-->/i
      end

      # Output path relative to build dir, e.g. "2024/03/15/my-post/index.html"
      def output_path
        File.join(permalink.sub(%r{\A/}, ""), "index.html")
      end

      private

      def parse_filename!
        stem = File.basename(@path, ".*")
        m = FILENAME_RE.match(stem)
        @date = Date.parse(m[1])
        @slug = m[2]
      end

      def parse_content!
        content = File.read(@path)
        if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
          @front    = (YAML.safe_load($1) || {}).transform_keys(&:downcase)
          @raw_body = $2
        else
          @front    = {}
          @raw_body = content
        end
        @title    = @front["title"]    || @slug.gsub("-", " ").split.map(&:capitalize).join(" ")
        @author   = @front["author"]   || @config["author"]
        @category = @front["category"] || infer_category
      end

      # Expose any frontmatter key as a method: article.my_custom_field
      def method_missing(name, *args)
        key = name.to_s
        @front.key?(key) ? @front[key] : super
      end

      def respond_to_missing?(name, include_private = false)
        @front.key?(name.to_s) || super
      end

      # If the file lives in a subdirectory of content/articles/, use that dir name
      def infer_category
        articles_dir = File.expand_path(File.join(@config["content_dir"], "articles"))
        file_dir     = File.expand_path(File.dirname(@path))
        return nil if file_dir == articles_dir
        File.basename(file_dir)
      end
    end
  end
end
