require "yaml"

module Tika
  class ConfigError < StandardError; end

  class Config < Hash
    # Keys the app cannot function without. A clear error is raised if any
    # of these are absent from config.yml rather than silently defaulting.
    REQUIRED_KEYS = %w[title theme content_dir build_dir posts_per_page].freeze

    def self.load(path = "config.yml")
      unless File.exist?(path)
        raise ConfigError, "config.yml not found. Run `tika init` to create a new site."
      end

      data = YAML.safe_load(File.read(path)) || {}

      missing = REQUIRED_KEYS.reject { |k| data.key?(k) }
      unless missing.empty?
        raise ConfigError, "config.yml is missing required keys: #{missing.join(", ")}"
      end

      config = new
      data.each { |k, v| config[k] = v }
      config
    end

    # Convenience accessors: config.title instead of config["title"]
    def method_missing(name, *args)
      key = name.to_s
      self.key?(key) ? self[key] : super
    end

    def respond_to_missing?(name, include_private = false)
      self.key?(name.to_s) || super
    end
  end
end
