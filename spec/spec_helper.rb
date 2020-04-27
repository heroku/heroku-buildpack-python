ENV['HATCHET_BUILDPACK_BASE'] = 'https://github.com/heroku/heroku-buildpack-python.git'

require 'rspec/core'
require 'rspec/retry'
require 'hatchet'

require 'date'

RSpec.configure do |config|
  config.full_backtrace      = true
  config.verbose_retry       = true # show retry status in spec process
  config.default_retry_count = 2 if ENV['IS_RUNNING_ON_CI'] # retry all tests that fail again
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

DEFAULT_STACK = 'heroku-18'

def run!(cmd)
  out = `#{cmd}`
  raise "Error running command #{cmd} with output: #{out}" unless $?.success?
  return out
end
