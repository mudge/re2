Gem::Specification.new do |s|
  s.name = "re2"
  s.summary = "Ruby bindings to re2."
  s.description = 'Ruby bindings to re2, "an efficient, principled regular expression library".'
  s.version = "0.1.1"
  s.authors = ["Paul Mucur"]
  s.homepage = "http://github.com/mudge/re2"
  s.email = "ruby.re2@librelist.com"
  s.extensions = ["ext/re2/extconf.rb"]
  s.files = [
    "ext/re2/extconf.rb",
    "ext/re2/re2.cc",
    "LICENSE.txt",
    "README.md",
    "Rakefile"
  ]
  s.test_files = ["test/re2_test.rb", "test/leak.rb"]
  s.add_development_dependency("rake-compiler")
end
