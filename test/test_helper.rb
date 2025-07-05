# External dependencies
require "debug" if ENV.fetch("DEBUG", "false").casecmp?("true")

# The last thing before loading this gem is to set up code coverage
begin
  # This does not require "simplecov", but
  require "kettle-soup-cover"
  #   this next line has a side-effect of running `.simplecov`
  require "simplecov" if defined?(Kettle::Soup::Cover) && Kettle::Soup::Cover::DO_COV
rescue LoadError
  nil
end

# Testing libraries
require "minitest/autorun"

# Internal dependencies & mixins
require_relative "testutil"
