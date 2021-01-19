# frozen_string_literal: true

ENV['HATCHET_BUILDPACK_BASE'] = 'https://github.com/heroku/heroku-buildpack-python.git'

require 'English'

require 'rspec/core'
require 'hatchet'

DEFAULT_STACK = ENV['STACK'] || 'heroku-20'

LATEST_PYTHON_2_7 = '2.7.18'
LATEST_PYTHON_3_4 = '3.4.10'
LATEST_PYTHON_3_5 = '3.5.10'
LATEST_PYTHON_3_6 = '3.6.12'
LATEST_PYTHON_3_7 = '3.7.9'
LATEST_PYTHON_3_8 = '3.8.7'
LATEST_PYTHON_3_9 = '3.9.1'
LATEST_PYPY_2_7 = '7.3.2'
LATEST_PYPY_3_6 = '7.3.2'
DEFAULT_PYTHON_VERSION = LATEST_PYTHON_3_6

RSpec.configure do |config|
  # Disables the legacy rspec globals and monkey-patched `should` syntax.
  config.disable_monkey_patching!
  # Enable flags like --only-failures and --next-failure.
  config.example_status_persistence_file_path = '.rspec_status'
  # Allows limiting a spec run to individual examples or groups by tagging them
  # with `:focus` metadata via the `fit`, `fcontext` and `fdescribe` aliases.
  config.filter_run_when_matching :focus
  # Allows declaring on which stacks a test/group should run by tagging it with `stacks`.
  config.filter_run_excluding stacks: ->(stacks) { !stacks.include?(DEFAULT_STACK) }
end

def new_app(*args, **kwargs)
  # Wrapping app creation to set the default stack, in lieu of being able to configure it globally:
  # https://github.com/heroku/hatchet/issues/163
  kwargs[:stack] ||= DEFAULT_STACK
  Hatchet::Runner.new(*args, **kwargs)
end

def clean_output(output)
  # Remove trailing whitespace characters added by Git:
  # https://github.com/heroku/hatchet/issues/162
  output.gsub(/ {8}(?=\R)/, '')
end

def update_buildpacks(app, buildpacks)
  # Updates the list of buildpacks for an existing app, until Hatchet supports this natively:
  # https://github.com/heroku/hatchet/issues/166
  buildpack_list = buildpacks.map { |b| { buildpack: (b == :default ? app.class.default_buildpack : b) } }
  app.api_rate_limit.call.buildpack_installation.update(app.name, updates: buildpack_list)
end

def run!(cmd)
  out = `#{cmd}`
  raise "Error running command #{cmd} with output: #{out}" unless $CHILD_STATUS.success?

  out
end
