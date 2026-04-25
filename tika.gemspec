Gem::Specification.new do |s|
  s.name        = "tika"
  s.version     = "0.1.1"
  s.summary     = "A static site generator"
  s.description = "Generates a static blog from Markdown/text files with ERB templates"
  s.author      = "Nathan Buggia"
  s.email       = ""
  s.homepage    = "https://github.com/nbuggia/tika"
  s.license     = "MIT"
  s.files       = Dir["lib/**/*", "bin/*", "assets/**/*", "README.md"]
  s.bindir      = "bin"
  s.executables = ["tika"]
  s.required_ruby_version = ">= 2.6"

  s.add_dependency "kramdown",   "~> 2.0"

  s.add_development_dependency "minitest",  "~> 5.0"
  s.add_development_dependency "simplecov", "~> 0.21"
  s.add_development_dependency "rake",      "~> 13.0"
end
