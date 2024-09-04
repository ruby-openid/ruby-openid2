require File.expand_path("lib/openid/version", __dir__)

Gem::Specification.new do |s|
  s.name = "ruby-openid"
  s.author = "JanRain, Inc"
  s.email = "openid@janrain.com"
  s.homepage = "https://github.com/openid/ruby-openid"
  s.summary = "A library for consuming and serving OpenID identities."
  s.version = OpenID::VERSION
  s.licenses = ["Ruby", "Apache Software License 2.0"]

  # Files
  files = Dir.glob("{examples,lib,test}/**/*")
  files << "NOTICE" << "CHANGELOG.md"
  s.files = files.delete_if { |f| f.include?("_darcs") || f.include?("admin") }
  s.require_paths = ["lib"]
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }

  # RDoc
  s.extra_rdoc_files = ["README.md", "INSTALL.md", "LICENSE", "UPGRADE.md"]
  s.rdoc_options << "--main" << "README.md"

  s.add_development_dependency("minitest", ">= 5")
  s.add_development_dependency("rake", ">= 13")
  s.add_development_dependency("rexml", "~> 3.2")
  s.add_development_dependency("webrick", "~> 1.8")

  # Coverage
  s.add_development_dependency("kettle-soup-cover", "~> 1.0", ">= 1.0.2")

  # Linting
  s.add_development_dependency("rubocop-lts", "~> 18.2", ">= 18.2.1")
  s.add_development_dependency("rubocop-minitest", "~> 0.36")
  s.add_development_dependency("rubocop-packaging", "~> 0.5", ">= 0.5.2")
  s.add_development_dependency("standard", ">= 1.35.1")

  # Documentation
  s.add_development_dependency("yard", "~> 0.9", ">= 0.9.34")
  s.add_development_dependency("yard-junk", "~> 0.0")
end
