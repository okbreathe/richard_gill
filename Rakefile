require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "richard_gill"
    gem.summary = %Q{Versioning/Activity plugin for DataMapper}
    gem.description = %Q{Versioning/Activity plugin for DataMapper}
    gem.email = "asher.vanbrunt@okbreathe.com"
    gem.homepage = "http://github.com/okbreathe/richard_gill"
    gem.authors = ["Asher Van Brunt"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_dependency "dm-core", ">= 1.0.0"
    gem.add_dependency "dm-types" , ">= 1.0.0"
    gem.add_dependency "dm-timestamps" , ">= 1.0.0"
    gem.add_dependency "dm-aggregates", ">= 1.0.0"
    gem.add_dependency "activesupport", ">=2.3.5"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "richard_gill #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
