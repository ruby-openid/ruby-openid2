# frozen_string_literal: true

require "version_gem"
require_relative "openid2/version"

module OpenID
end

OpenID::Version.class_eval do
  extend VersionGem::Basic
end
