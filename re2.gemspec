# frozen_string_literal: true

require_relative 'lib/re2/version'

Gem::Specification.new do |s|
  s.name = "re2"
  s.summary = "Ruby bindings to RE2."
  s.description = 'Ruby bindings to RE2, "a fast, safe, thread-friendly alternative to backtracking regular expression engines like those used in PCRE, Perl, and Python".'
  s.version = RE2::VERSION
  s.authors = ["Paul Mucur", "Stan Hu"]
  s.homepage = "https://github.com/mudge/re2"
  s.extensions = ["ext/re2/extconf.rb"]
  s.license = "BSD-3-Clause"
  s.required_ruby_version = ">= 2.6.0"
  s.files = [
    "dependencies.yml",
    "ext/re2/extconf.rb",
    "ext/re2/re2.cc",
    "ext/re2/recipes.rb",
    "Gemfile",
    "lib/re2.rb",
    "lib/re2/regexp.rb",
    "lib/re2/scanner.rb",
    "lib/re2/string.rb",
    "lib/re2/version.rb",
    "LICENSE.txt",
    "LICENSE-DEPENDENCIES.txt",
    "README.md",
    "Rakefile",
    "re2.gemspec"
  ]
  s.test_files = [
    ".rspec",
    "spec/spec_helper.rb",
    "spec/re2_spec.rb",
    "spec/kernel_spec.rb",
    "spec/re2/regexp_spec.rb",
    "spec/re2/match_data_spec.rb",
    "spec/re2/string_spec.rb",
    "spec/re2/set_spec.rb",
    "spec/re2/scanner_spec.rb"
  ]
  s.add_development_dependency("rake-compiler", "~> 1.2.7")
  s.add_development_dependency("rake-compiler-dock", "~> 1.9.1")
  s.add_development_dependency("rspec", "~> 3.2")
  s.add_runtime_dependency("mini_portile2", "~> 2.8.7") # keep version in sync with extconf.rb
end
