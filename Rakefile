# frozen_string_literal: true

require 'rake/extensiontask'
require 'rspec/core/rake_task'
require 'rake_compiler_dock'
require 'yaml'

require_relative 'ext/re2/recipes'

CLEAN.include FileList['**/*{.o,.so,.dylib,.bundle}'],
              FileList['**/extconf.h'],
              FileList['**/Makefile'],
              FileList['pkg/']

CLOBBER.include FileList['**/tmp'],
                FileList['**/*.log'],
                FileList['doc/**'],
                FileList['tmp/']
CLOBBER.add("ports/*").exclude(%r{ports/archives$})

RE2_GEM_SPEC = Gem::Specification.load('re2.gemspec')

task :prepare do
  puts "Preparing project for gem building..."
  recipes = load_recipes
  recipes.each { |recipe| recipe.download }
end

task gem: :prepare

Gem::PackageTask.new(RE2_GEM_SPEC) do |p|
  p.need_zip = false
  p.need_tar = false
end

CROSS_RUBY_VERSIONS = %w[3.3.0 3.2.0 3.1.0 3.0.0 2.7.0 2.6.0].join(':')
CROSS_RUBY_PLATFORMS = %w[
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

ENV['RUBY_CC_VERSION'] = CROSS_RUBY_VERSIONS

Rake::ExtensionTask.new('re2', RE2_GEM_SPEC) do |e|
  e.cross_compile = true
  e.cross_config_options << '--enable-cross-build'
  e.config_options << '--disable-system-libraries'
  e.cross_platform = CROSS_RUBY_PLATFORMS
  e.cross_compiling do |spec|
    spec.files.reject! { |path| File.fnmatch?('ports/*', path) }
    spec.dependencies.reject! { |dep| dep.name == 'mini_portile2' }
  end
end

RSpec::Core::RakeTask.new(:spec)

namespace 'gem' do
  def gem_builder(platform)
    # use Task#invoke because the pkg/*gem task is defined at runtime
    Rake::Task["native:#{platform}"].invoke
    Rake::Task["pkg/#{RE2_GEM_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
  end

  CROSS_RUBY_PLATFORMS.each do |platform|
    # The Linux x86 image (ghcr.io/rake-compiler/rake-compiler-dock-image:1.3.0-mri-x86_64-linux)
    # is based on CentOS 7 and has two versions of cmake installed:
    # a 2.8 version in /usr/bin and a 3.25 in /usr/local/bin. The latter is needed by abseil.
    cmake =
      case platform
      when 'x86_64-linux', 'x86-linux'
        '/usr/local/bin/cmake'
      else
        'cmake'
      end

    desc "build native gem for #{platform} platform"
    task platform do
      RakeCompilerDock.sh <<~SCRIPT, platform: platform, verbose: true
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{platform}:builder CMAKE=#{cmake}
      SCRIPT
    end

    namespace platform do
      desc "build native gem for #{platform} platform (guest container)"
      task 'builder' do
        gem_builder(platform)
      end
    end
  end

  desc 'build all native gems'
  multitask 'native' => CROSS_RUBY_PLATFORMS
end

def add_file_to_gem(relative_source_path)
  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p dest_dir unless Dir.exist?(dest_dir)
  rm_f dest_path if File.exist?(dest_path)
  safe_ln relative_source_path, dest_path

  RE2_GEM_SPEC.files << relative_source_path
end

def gem_build_path
  File.join 'pkg', RE2_GEM_SPEC.full_name
end

def add_vendored_libraries
  dependencies = YAML.load_file(File.join(File.dirname(__FILE__), 'dependencies.yml'))
  abseil_archive = File.join('ports', 'archives', "#{dependencies['abseil']['version']}.tar.gz")
  libre2_archive = File.join('ports', 'archives', "re2-#{dependencies['libre2']['version']}.tar.gz")

  add_file_to_gem(abseil_archive)
  add_file_to_gem(libre2_archive)
end

task gem_build_path do
  add_vendored_libraries
end

task default: [:compile, :spec]
