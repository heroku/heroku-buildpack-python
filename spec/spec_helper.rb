# frozen_string_literal: true

ENV['HATCHET_BUILDPACK_BASE'] = 'https://github.com/heroku/heroku-buildpack-python.git'

require 'English'

require 'rspec/core'
require 'hatchet'

DEFAULT_STACK = ENV['STACK'] || 'heroku-18'

RSpec.configure do |config|
  # Disables the legacy rspec globals and monkey-patched `should` syntax.
  config.disable_monkey_patching!
  # Enable flags like --only-failures and --next-failure.
  config.example_status_persistence_file_path = '.rspec_status'
  # Allows limiting a spec run to individual examples or groups by tagging them
  # with `:focus` metadata via the `fit`, `fcontext` and `fdescribe` aliases.
  config.filter_run_when_matching :focus
end

def new_app(*args, **kwargs)
  # Wrapping app creation to set the default stack, in lieu of being able to configure it globally:
  # https://github.com/heroku/hatchet/issues/163
  kwargs[:stack] ||= DEFAULT_STACK
  Hatchet::Runner.new(*args, **kwargs)
end

def run!(cmd)
  out = `#{cmd}`
  raise "Error running command #{cmd} with output: #{out}" unless $CHILD_STATUS.success?

  out
end
