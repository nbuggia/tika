require_relative "../test_helper"

class ConfigTest < TikaTest
  include TestHelpers

  # ---------------------------------------------------------------------------
  # Loading
  # ---------------------------------------------------------------------------

  def test_load_from_yaml
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, <<~YAML)
        title:           "My Site"
        author:          "Alice"
        description:     "Personal site"
        base_url:        "https://alice.com"
        theme:           "custom"
        posts_per_page:  5
        feed_entries:    15
        permalink_style: "flat"
        content_dir:     "content"
        build_dir:       "build"
        twitter:         "alice"
        google_analytics_id: "G-ABC"
      YAML

      config = Tika::Config.load(path)
      assert_equal "My Site",           config["title"]
      assert_equal "Alice",             config["author"]
      assert_equal "Personal site",     config["description"]
      assert_equal "https://alice.com", config["base_url"]
      assert_equal "custom",            config["theme"]
      assert_equal 5,                   config["posts_per_page"]
      assert_equal 15,                  config["feed_entries"]
      assert_equal "flat",              config["permalink_style"]
      assert_equal "alice",             config["twitter"]
      assert_equal "G-ABC",             config["google_analytics_id"]
    end
  end

  def test_all_keys_from_yaml_are_available
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, <<~YAML)
        title:            "My Site"
        theme:            "default"
        content_dir:      "content"
        build_dir:        "build"
        posts_per_page:   5
        my_custom_key:    "hello"
        another_key:      42
      YAML

      config = Tika::Config.load(path)
      assert_equal "hello", config["my_custom_key"]
      assert_equal 42,      config["another_key"]
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  def test_raises_when_config_file_missing
    err = assert_raises(Tika::ConfigError) { Tika::Config.load("nonexistent.yml") }
    assert_match(/config.yml not found/, err.message)
    assert_match(/tika init/, err.message)
  end

  def test_raises_when_required_keys_missing
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, "title: \"Only Title\"\n")
      err = assert_raises(Tika::ConfigError) { Tika::Config.load(path) }
      assert_match(/missing required keys/, err.message)
      assert_match(/theme/, err.message)
      assert_match(/content_dir/, err.message)
      assert_match(/build_dir/, err.message)
      assert_match(/posts_per_page/, err.message)
    end
  end

  def test_raises_for_empty_yaml
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, "")
      assert_raises(Tika::ConfigError) { Tika::Config.load(path) }
    end
  end

  def test_no_error_when_all_required_keys_present
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, <<~YAML)
        title:          "Site"
        theme:          "default"
        content_dir:    "content"
        build_dir:      "build"
        posts_per_page: 10
      YAML
      assert Tika::Config.load(path).is_a?(Tika::Config)
    end
  end

  # ---------------------------------------------------------------------------
  # Accessors
  # ---------------------------------------------------------------------------

  def test_method_missing_accessor
    config = config_from_yaml
    assert_equal config["title"],  config.title
    assert_equal config["author"], config.author
    assert_equal config["theme"],  config.theme
  end

  def test_respond_to_known_keys
    config = config_from_yaml
    assert config.respond_to?(:title)
    assert config.respond_to?(:author)
  end

  def test_method_missing_raises_for_unknown_key
    config = config_from_yaml
    assert_raises(NoMethodError) { config.nonexistent_key }
  end

  def test_custom_key_accessible_as_method
    Dir.mktmpdir do |dir|
      path = File.join(dir, "config.yml")
      File.write(path, DEFAULT_CONFIG_YAML + "my_flag: true\n")
      config = Tika::Config.load(path)
      assert_equal true, config.my_flag
    end
  end
end
