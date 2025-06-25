#!/usr/bin/env rake
require "bundler/gem_tasks"

require "rake/testtask"

desc "Run tests"
Rake::TestTask.new("test") do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = false
end

begin
  require "rubocop/lts"
  Rubocop::Lts.install_tasks
rescue LoadError
  task(:rubocop_gradual) do
    warn("RuboCop (Gradual) is disabled")
  end
end

begin
  require "yard-junk/rake"

  YardJunk::Rake.define_task
rescue LoadError
  task("yard:junk") do
    warn("yard:junk is disabled")
  end
end

begin
  require "yard"

  YARD::Rake::YardocTask.new do |t|
    t.files = ["lib/**/*.rb"]
    t.stats_options = ["--list-undoc"] if ENV.fetch("VERBOSE", "false").casecmp?("true")
  end
rescue LoadError
  task(:yard) do
    warn("yard is disabled")
  end
end

task default: %i[test rubocop_gradual:autocorrect yard yard:junk]
