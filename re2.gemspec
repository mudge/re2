Gem::Specification.new do |s|
  s.name = "re2"
  s.summary = "Ruby bindings to re2."
  s.description = 'Ruby bindings to re2, "an efficient, principled regular expression library".'
  s.version = "1.4.0"
  s.authors = ["Paul Mucur"]
  s.homepage = "https://github.com/mudge/re2"
  s.extensions = ["ext/re2/extconf.rb"]
  s.license = "BSD-3-Clause"
  s.files = [
    "ext/re2/extconf.rb",
    "ext/re2/re2.cc",
    "lib/re2.rb",
    "lib/re2/scanner.rb",
    "lib/re2/string.rb",
    "LICENSE.txt",
    "README.md",
    "Rakefile"
  ]
  s.test_files = [
    "spec/spec_helper.rb",
    "spec/re2_spec.rb",
    "spec/kernel_spec.rb",
    "spec/re2/regexp_spec.rb",
    "spec/re2/match_data_spec.rb",
    "spec/re2/string_spec.rb",
    "spec/re2/scanner_spec.rb"
  ]
  s.add_development_dependency("rake-compiler", "~> 0.9")
  s.add_development_dependency("rspec", "~> 3.2")
end
