# frozen_string_literal: true

# HOW TO UPDATE APPRAISALS:
#   BUNDLE_GEMFILE=Appraisal.root.gemfile bundle
#   BUNDLE_GEMFILE=Appraisal.root.gemfile bundle exec appraisal update
#   bundle exec rake rubocop_gradual:autocorrect

# Used for HEAD (nightly) releases of ruby, truffleruby, and jruby.
# Split into discrete appraisals if one of them needs a dependency locked discretely.
appraise "dep-heads" do
  eval_gemfile "modular/runtime_heads.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 2.7
# Test Matrix:
#   - Ruby 2.7
appraise "r2" do
  eval_gemfile "modular/x_std_libs/r2/libs.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 2.7
# Test Matrix:
#   - Ruby 2.7
appraise "r2-set-1" do
  eval_gemfile "modular/x_std_libs/r2/set-1.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 2.7
# Test Matrix:
#   - Ruby 2.7
appraise "r2-set-2" do
  eval_gemfile "modular/x_std_libs/r2/set-2.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 3.0
#   - Ruby 3.2
#   - Ruby 3.3
#   - Ruby 3.4
#   - JRuby 10.0
appraise "r3" do
  eval_gemfile "modular/x_std_libs/r3/libs.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 3.0
# Test Matrix:
#   - Ruby 3.1
#   - JRuby 9.4
appraise "r3-set-1" do
  eval_gemfile "modular/x_std_libs/r3/set-1.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Compat: Ruby >= 3.0
# Test Matrix:
#   - Ruby 3.0
appraise "r3-set-2" do
  eval_gemfile "modular/x_std_libs/r3/set-2.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Only run security audit on the latest version of Ruby
appraise "audit" do
  eval_gemfile "modular/audit.gemfile"
  eval_gemfile "modular/x_std_libs/r3/libs.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Only run coverage on the latest version of Ruby
appraise "coverage" do
  eval_gemfile "modular/coverage.gemfile"
  gem "ostruct", "~> 0.6", ">= 0.6.1" # Ruby >= 2.5
  eval_gemfile "modular/x_std_libs/r3/libs.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end

# Only run linter on the latest version of Ruby (but, in support of the oldest supported Ruby version)
appraise "style" do
  eval_gemfile "modular/style.gemfile"
  eval_gemfile "modular/x_std_libs/r3/libs.gemfile"
  remove_gem "appraisal" # only present because it must be in the gemfile because we target a git branch
end
