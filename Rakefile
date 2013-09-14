require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('re2')

Rake::TestTask.new do |t|
  t.libs << "spec"
  t.test_files = FileList["spec/**/*_spec.rb"]
  t.verbose = true
end

task :test    => :compile
task :spec    => :test
task :default => :test

