require 'rake/extensiontask'
require 'rspec/core/rake_task'

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

Rake::ExtensionTask.new('re2')

Gem::PackageTask.new(RE2_GEM_SPEC) do |p|
  p.need_zip = false
  p.need_tar = false
end

RSpec::Core::RakeTask.new(:spec)

def gem_build_path
  File.join 'pkg', RE2_GEM_SPEC.full_name
end

def add_file_to_gem(relative_source_path)
  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p dest_dir unless Dir.exist?(dest_dir)
  rm_f dest_path if File.exist?(dest_path)
  safe_ln relative_source_path, dest_path

  RE2_GEM_SPEC.files << relative_source_path
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

task :spec    => :compile
task :default => :spec
