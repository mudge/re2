# frozen_string_literal: true

require 'rake/extensiontask'
require 'rake_compiler_dock'
require 'rspec/core/rake_task'
require 'yaml'

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
  aarch64-linux
  arm-linux
  arm64-darwin
  x64-mingw-ucrt
  x64-mingw32
  x86-linux
  x86-mingw32
  x86_64-darwin
  x86_64-linux
].freeze

ENV['RUBY_CC_VERSION'] = %w[3.3.0 3.2.0 3.1.0 3.0.0 2.7.0 2.6.0].join(':')

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

namespace 'gem' do
  cross_platforms.each do |platform|

    # Compile each platform's native gem, packaging up the result. Note we add
    # /usr/local/bin to the PATH as it contains the newest version of CMake in
    # the rake-compiler-dock images.
    desc "Compile and build native gem for #{platform} platform"
    task platform do
      RakeCompilerDock.sh <<~SCRIPT, platform: platform, verbose: true
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
