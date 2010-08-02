require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the identity_map plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the identity_map plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'IdentityMap'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ar-simple-idmap"
    gemspec.summary = "Simple identity map for ActiveRecord"
    gemspec.description = "Add simple finegrained handcontrolled identity map for ActiveRecord"
    gemspec.email = "funny.falcon@gmail.com"
    gemspec.homepage = "http://github.com/funny-falcon/identity-map"
    gemspec.authors = ["Sokolov Yura aka funny_falcon"]
    gemspec.add_dependency('activerecord')
    gemspec.rubyforge_project = 'ar-simple-idmap'
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
