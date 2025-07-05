#### IMPORTANT #######################################################
# Gemfile is for local development ONLY; Gemfile is NOT loaded in CI #
####################################################### IMPORTANT ####
# On CI we only need the gemspecs' dependencies (including development dependencies).
# Exceptions, if any, such as for Appraisals, are in gemfiles/*.gemfile

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }
git_source(:gitlab) { |repo_name| "https://gitlab.com/#{repo_name}" }

latest_ruby_version = Gem::Version.create("3.4")
current_ruby_version = Gem::Version.create(RUBY_VERSION)

### Std Lib Extracted Gems
eval_gemfile "gemfiles/modular/x_std_libs/r3/libs.gemfile"

# Specify your gem's dependencies in ruby-openid.gemspec
gemspec

### Debugging
eval_gemfile "gemfiles/modular/debug.gemfile"

### Documentation
# Only runs on the latest Ruby
if current_ruby_version >= latest_ruby_version
  eval_gemfile "gemfiles/modular/documentation.gemfile"
end

### Test Coverage
eval_gemfile "gemfiles/modular/coverage.gemfile"

### Testing
gem "appraisal", github: "pboling/appraisal", branch: "galtzo"
