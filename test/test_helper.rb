# External dependencies
begin
  require "debug" if ENV.fetch("DEBUG", "false").casecmp?("true")
rescue LoadError => error
  warn("[test_helper.rb] failed to load debug gem") unless ENV["BUNDLE_GEMFILE"]
  raise error unless error.message.include?("debug")
end

# The last thing before loading this gem is to set up code coverage
if ENV.fetch("COVERAGE", "false").casecmp?("true")
  begin
    # This does not require "simplecov", but
    require "kettle-soup-cover"
    #   this next line has a side effect of running `.simplecov`
    require "simplecov" if defined?(Kettle::Soup::Cover) && Kettle::Soup::Cover::DO_COV

    SimpleCov.external_at_exit = true
  rescue LoadError => error
    warn("[test_helper.rb] failed to load test coverage gems") unless ENV["BUNDLE_GEMFILE"]
    raise error unless error.message.include?("kettle")
  end
elsif ENV["BUNDLE_GEMFILE"]
  warn("[test_helper.rb] not loading test coverage gems; override with COVERAGE=true")
end

# Testing libraries
require "minitest/autorun"

# Internal dependencies & mixins
require_relative "testutil"
