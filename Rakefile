require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('re2')

RSpec::Core::RakeTask.new(:spec)

task :spec    => :compile
task :default => :spec

