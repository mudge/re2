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

Rake::ExtensionTask.new('re2')

RSpec::Core::RakeTask.new(:spec)

task :spec    => :compile
task :default => :spec

