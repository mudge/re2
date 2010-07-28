begin
  require 'rake/extensiontask'
  require 'rake/testtask'
rescue LoadError
  require 'rubygems'
  require 'rake/extensiontask'
  require 'rake/testtask'
end

Rake::ExtensionTask.new('re2') do |e|
  # e.config_options << "--with-re2-dir=/opt/local/re2"
end

Rake::TestTask.new do |t|
  t.test_files = FileList["test/*_test.rb"]
  t.verbose = true
end

task :test => :compile
task :default => :test

