require "rake/testtask"
require "fileutils"

ASSETS_DIR      = File.expand_path("assets")
EXAMPLE_SITE    = File.join(ASSETS_DIR, "example-site")
SAMPLE_SITE     = File.expand_path("test/sample-site")

# ---------------------------------------------------------------------------
# provision — copy example-site into test/sample-site/ fresh
# ---------------------------------------------------------------------------
desc "Provision test/sample-site/ from assets/example-site/"
task :provision do
  FileUtils.rm_rf(SAMPLE_SITE)
  FileUtils.cp_r(EXAMPLE_SITE, SAMPLE_SITE)
  FileUtils.cp_r(File.join(ASSETS_DIR, "themes"), File.join(SAMPLE_SITE, "themes"))
  puts "Provisioned: #{SAMPLE_SITE}"
end

# ---------------------------------------------------------------------------
# test — provision then run all unit and integration tests
# ---------------------------------------------------------------------------
Rake::TestTask.new(:test) do |t|
  t.libs    << "lib" << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end

task test: :provision

# ---------------------------------------------------------------------------
# serve — provision and serve the sample site at http://localhost:4000
# ---------------------------------------------------------------------------
desc "Build and serve the sample site at http://localhost:4000"
task serve: :provision do
  Dir.chdir(SAMPLE_SITE) do
    $LOAD_PATH.unshift(File.expand_path("lib", __dir__))
    require "tika"
    config = Tika::Config.load
    Tika::Server.new(config, port: 4000).start
  end
end

# ---------------------------------------------------------------------------
# release — test, build the gem, and push to RubyGems
# ---------------------------------------------------------------------------
desc "Run tests, build the gem, and push to RubyGems"
task release: :test do
  gemspec = Dir["*.gemspec"].first
  abort "No gemspec found" unless gemspec

  version = Gem::Specification.load(gemspec).version
  gem_file = "tika-#{version}.gem"

  sh "gem build #{gemspec}"
  abort "Build failed: #{gem_file} not found" unless File.exist?(gem_file)

  sh "gem push #{gem_file}"
  puts "Released tika #{version}"
end

# ---------------------------------------------------------------------------
# clean — remove all generated files
# ---------------------------------------------------------------------------
desc "Remove all generated files (build output, coverage, compiled gems)"
task :clean do
  targets = [
    SAMPLE_SITE,
    "coverage",
    *Dir["*.gem"],
  ]
  targets.each do |path|
    if File.exist?(path)
      FileUtils.rm_rf(path)
      puts "Removed: #{path}"
    end
  end
  puts "Clean."
end

task default: :test
