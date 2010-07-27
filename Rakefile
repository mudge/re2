begin
  require 'rake/extensiontask'
  require 'rake/testtask'
rescue LoadError
  require 'rubygems'
  require 'rake/extensiontask'
  require 'rake/testtask'
end

Rake::ExtensionTask.new('re2')

Rake::TestTask.new do |t|
  t.test_files = FileList["test/*_test.rb"]
  t.verbose = true
end

task :test => :compile
task :default => :test

