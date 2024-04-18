# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Heroku CI' do
  it 'installs both normal and test dependencies and uses cache on subsequent runs' do
    Hatchet::Runner.new('spec/fixtures/ci_requirements', allow_failure: true).run_ci do |test_run|
      expect(test_run.output).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
        -----> Python app detected
        -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
               To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
        -----> Installing python-#{DEFAULT_PYTHON_VERSION}
        -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        -----> Installing SQLite3
        -----> Installing requirements with pip
               .*
               Successfully installed urllib3-.*
        -----> Installing test dependencies...
               .*
               Successfully installed .* pytest-.*
        -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
        -----> No test-setup command provided. Skipping.
        -----> Running test command `pytest --version`...
        pytest .*
        -----> test command `pytest --version` completed successfully
      REGEX

      test_run.run_again

      expect(test_run.output).to match(Regexp.new(<<~REGEX))
        -----> Python app detected
        -----> No Python version was specified. Using the same version as the last build: python-#{DEFAULT_PYTHON_VERSION}
               To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
        -----> No change in requirements detected, installing from cache
        -----> Using cached install of python-#{DEFAULT_PYTHON_VERSION}
        -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        -----> Installing SQLite3
        -----> Installing requirements with pip
        -----> Installing test dependencies...
        -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
        -----> No test-setup command provided. Skipping.
        -----> Running test command `pytest --version`...
        pytest .*
        -----> test command `pytest --version` completed successfully
      REGEX
    end
  end
end
