# frozen_string_literal: true

# Keep the historical OpenID protocol suite in the generated RSpec workflow
# until it is intentionally migrated. Minitest::Test still provides the
# assertions and lifecycle for these legacy tests.
# RSpec's formatter and file-selection switches are not valid Minitest
# switches. Preserve only the shared random seed before loading the suite.
seed_index = ARGV.index("--seed")
ARGV.replace(seed_index ? ["--seed", ARGV.fetch(seed_index + 1)] : [])
Dir[File.expand_path("../test/test_*.rb", __dir__)].sort.each do |path|
  require path
end
