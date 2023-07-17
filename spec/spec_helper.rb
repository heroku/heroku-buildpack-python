# frozen_string_literal: true

ENV['HATCHET_BUILDPACK_BASE'] ||= 'https://github.com/heroku/heroku-buildpack-python.git'
ENV['HATCHET_DEFAULT_STACK'] ||= 'heroku-22'

require 'rspec/core'
require 'hatchet'

LATEST_PYTHON_3_7 = '3.7.17'
LATEST_PYTHON_3_8 = '3.8.17'
LATEST_PYTHON_3_9 = '3.9.17'
LATEST_PYTHON_3_10 = '3.10.12'
LATEST_PYTHON_3_11 = '3.11.4'
DEFAULT_PYTHON_VERSION = LATEST_PYTHON_3_11

# The requirement versions are effectively buildpack constants, however, we want
# Dependabot to be able to update them, which requires that they be in requirements
# files. The requirements files contain contents like `package==1.2.3` (and not just
# the package version) so we have to extract the version substring from it.
def get_requirement_version(package_name)
  requirement = File.read("requirements/#{package_name}.txt").strip
  requirement.delete_prefix("#{package_name}==")
end

PIP_VERSION = get_requirement_version('pip')
SETUPTOOLS_VERSION = get_requirement_version('setuptools')
WHEEL_VERSION = get_requirement_version('wheel')
PIPENV_VERSION = get_requirement_version('pipenv')

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
  config.filter_run_excluding stacks: ->(stacks) { !stacks.include?(ENV.fetch('HATCHET_DEFAULT_STACK')) }
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
