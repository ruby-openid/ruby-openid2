# for auto-loading from bundler
require "version_gem"
require_relative "openid/version"

OpenID::Version.class_eval do
  extend VersionGem::Basic
end

require_relative "openid"
