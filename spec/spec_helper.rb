# frozen_string_literal: true

ENV['HATCHET_BUILDPACK_BASE'] ||= 'https://github.com/heroku/heroku-buildpack-python.git'
ENV['HATCHET_DEFAULT_STACK'] ||= 'heroku-20'

require 'rspec/core'
require 'hatchet'

LATEST_PYTHON_2_7 = '2.7.18'
LATEST_PYTHON_3_4 = '3.4.10'
LATEST_PYTHON_3_5 = '3.5.10'
LATEST_PYTHON_3_6 = '3.6.15'
LATEST_PYTHON_3_7 = '3.7.12'
LATEST_PYTHON_3_8 = '3.8.12'
LATEST_PYTHON_3_9 = '3.9.9'
LATEST_PYTHON_3_10 = '3.10.1'
LATEST_PYPY_2_7 = '7.3.2'
LATEST_PYPY_3_6 = '7.3.2'
DEFAULT_PYTHON_VERSION = LATEST_PYTHON_3_9

# Work around the return value for `default_buildpack` changing after deploy:
# https://github.com/heroku/hatchet/issues/180
# Once we've updated to Hatchet release that includes the fix, consumers
# of this can switch back to using `app.class.default_buildpack`
DEFAULT_BUILDPACK_URL = Hatchet::App.default_buildpack

RSpec.configure do |config|
  # Disables the legacy rspec globals and monkey-patched `should` syntax.
  config.disable_monkey_patching!
  # Enable flags like --only-failures and --next-failure.
  config.example_status_persistence_file_path = '.rspec_status'
  # Allows limiting a spec run to individual examples or groups by tagging them
  # with `:focus` metadata via the `fit`, `fcontext` and `fdescribe` aliases.
  config.filter_run_when_matching :focus
  # Allows declaring on which stacks a test/group should run by tagging it with `stacks`.
  config.filter_run_excluding stacks: ->(stacks) { !stacks.include?(ENV['HATCHET_DEFAULT_STACK']) }
end

def clean_output(output)
  # Remove trailing whitespace characters added by Git:
  # https://github.com/heroku/hatchet/issues/162
  output.gsub(/ {8}(?=\R)/, '')
end

def update_buildpacks(app, buildpacks)
  # Updates the list of buildpacks for an existing app, until Hatchet supports this natively:
  # https://github.com/heroku/hatchet/issues/166
  buildpack_list = buildpacks.map { |b| { buildpack: (b == :default ? DEFAULT_BUILDPACK_URL : b) } }
  app.api_rate_limit.call.buildpack_installation.update(app.name, updates: buildpack_list)
end
