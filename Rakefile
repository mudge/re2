# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake_compiler_dock'
require 'rspec/core/rake_task'

require_relative 'ext/re2/recipes'

re2_gemspec = Gem::Specification.load('re2.gemspec')
abseil_recipe, re2_recipe = load_recipes

# Add Abseil and RE2's latest archives to the gem files. (Note these will be
# removed from the precompiled native gems.)
abseil_archive = File.join("ports/archives", File.basename(abseil_recipe.files[0][:url]))
re2_archive = File.join("ports/archives", File.basename(re2_recipe.files[0][:url]))

re2_gemspec.files << abseil_archive
re2_gemspec.files << re2_archive

cross_platforms = %w[
  aarch64-linux-gnu
  aarch64-linux-musl
  arm-linux-gnu
  arm-linux-musl
  arm64-darwin
  x64-mingw-ucrt
  x64-mingw32
  x86-linux-gnu
  x86-linux-musl
  x86-mingw32
  x86_64-darwin
  x86_64-linux-gnu
  x86_64-linux-musl
].freeze

RakeCompilerDock.set_ruby_cc_version("~> 2.6", "~> 3.0")

Gem::PackageTask.new(re2_gemspec).define

Rake::ExtensionTask.new('re2', re2_gemspec) do |e|
  e.cross_compile = true
  e.cross_config_options << '--enable-cross-build'
  e.config_options << '--disable-system-libraries'
  e.cross_platform = cross_platforms
  e.cross_compiling do |spec|
    spec.files.reject! { |path| File.fnmatch?('ports/*', path) }
    spec.dependencies.reject! { |dep| dep.name == 'mini_portile2' }
  end
end

RSpec::Core::RakeTask.new(:spec)

begin
  require 'ruby_memcheck'
  require 'ruby_memcheck/rspec/rake_task'

  namespace :spec do
    RubyMemcheck::RSpec::RakeTask.new(valgrind: :compile)
  end
rescue LoadError
  # Only define the spec:valgrind task if ruby_memcheck is installed
end

namespace :gem do
  cross_platforms.each do |platform|

    # Compile each platform's native gem, packaging up the result. Note we add
    # /usr/local/bin to the PATH as it contains the newest version of CMake in
    # the rake-compiler-dock images.
    desc "Compile and build native gem for #{platform} platform"
    task platform do
      RakeCompilerDock.sh <<~SCRIPT, platform: platform, verbose: true
        rbenv shell 3.1.6 &&
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake native:#{platform} pkg/#{re2_gemspec.full_name}-#{Gem::Platform.new(platform)}.gem PATH="/usr/local/bin:$PATH"
      SCRIPT
    end
  end
end

# Set up file tasks for Abseil and RE2's archives so they are automatically
# downloaded when required by the gem task.
file abseil_archive do
  abseil_recipe.download
end

file re2_archive do
  re2_recipe.download
end

task default: :spec

CLEAN.add("lib/**/*.{o,so,bundle}", "pkg")
CLOBBER.add("ports")
