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

task default: %i[test rubocop_gradual]
