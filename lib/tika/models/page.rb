require "yaml"
require "kramdown"
require "erb"

module Tika
  module Models
    # Custom pages (about, contact, etc.) — files in content/pages/
    # Supports both Markdown (.md, .txt) and ERB (.html.erb) formats.
    class Page
      attr_reader :path, :slug, :title, :raw_body

      def initialize(path, config)
        @path   = path
        @config = config
        @slug   = File.basename(path, ".*").sub(/\.html\z/, "")
        parse_content!
      end

      def body
        if erb?
          ERB.new(@raw_body, trim_mode: "-").result(binding)
        else
          Kramdown::Document.new(@raw_body).to_html
        end
      end

      def permalink
        "/#{@slug}/"
      end

      def output_path
        "#{@slug}/index.html"
      end

      private

      def erb?
        @path.end_with?(".erb")
      end

      def parse_content!
        content = File.read(@path)
        if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
          front     = YAML.safe_load($1) || {}
          @raw_body = $2
        else
          front     = {}
          @raw_body = content
        end
        @title = front["title"] || front["Title"] || @slug.gsub("-", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
