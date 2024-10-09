# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Heroku CI' do
  let(:buildpacks) { [:default, 'heroku-community/inline'] }

  context 'when using pip' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_requirements', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        expect(test_run.output).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          -----> Python app detected
          -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
                 To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          -----> Installing SQLite3
          -----> Installing requirements with pip
                 .*
                 Successfully installed typing-extensions-4.12.2
          -----> Installing test dependencies...
                 .*
                 Successfully installed .* pytest-8.3.3
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running post-compile hook
          CI=true
          CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          C_INCLUDE_PATH=/app/.heroku/python/include
          DISABLE_COLLECTSTATIC=1
          INSTALL_TEST=1
          LANG=en_US.UTF-8
          LC_ALL=C.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PIP_NO_PYTHON_VERSION_WARNING=1
          PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          PYTHONUNBUFFERED=1
          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PYTHONHASHSEED=random
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          -----> No test-setup command provided. Skipping.
          -----> Running test command `./bin/print-env-vars.sh && pytest --version`...
          CI=true
          DYNO_RAM=2560
          FORWARDED_ALLOW_IPS=\\*
          GUNICORN_CMD_ARGS=--access-logfile -
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/:/app/.sprettur/bin/
          PYTHONHASHSEED=random
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=5
          pytest 8.3.3
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again

        expect(test_run.output).to include(<<~OUTPUT)
          -----> Python app detected
          -----> No Python version was specified. Using the same version as the last build: Python #{DEFAULT_PYTHON_FULL_VERSION}
                 To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          -----> No change in requirements detected, installing from cache
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          -----> Installing SQLite3
          -----> Installing requirements with pip
          -----> Installing test dependencies...
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running post-compile hook
        OUTPUT
      end
    end
  end

  context 'when using Pipenv' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_pipenv', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        expect(test_run.output).to match(Regexp.new(<<~REGEX))
          -----> Python app detected
          -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
                 To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          -----> Installing Pipenv #{PIPENV_VERSION}
          -----> Installing SQLite3
          -----> Installing test dependencies with Pipenv
                 Installing dependencies from Pipfile.lock \\(.+\\)...
                 Installing dependencies from Pipfile.lock \\(.+\\)...
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running post-compile hook
          CI=true
          CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          C_INCLUDE_PATH=/app/.heroku/python/include
          DISABLE_COLLECTSTATIC=1
          INSTALL_TEST=1
          LANG=en_US.UTF-8
          LC_ALL=C.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PIP_NO_PYTHON_VERSION_WARNING=1
          PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          PYTHONUNBUFFERED=1
          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PYTHONHASHSEED=random
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          -----> No test-setup command provided. Skipping.
          -----> Running test command `./bin/print-env-vars.sh && pytest --version`...
          CI=true
          DYNO_RAM=2560
          FORWARDED_ALLOW_IPS=\\*
          GUNICORN_CMD_ARGS=--access-logfile -
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/:/app/.sprettur/bin/
          PYTHONHASHSEED=random
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=5
          pytest 8.3.3
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again

        expect(test_run.output).to match(Regexp.new(<<~REGEX))
          -----> Python app detected
          -----> No Python version was specified. Using the same version as the last build: Python #{DEFAULT_PYTHON_FULL_VERSION}
                 To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          -----> Installing Pipenv #{PIPENV_VERSION}
          -----> Installing SQLite3
          -----> Installing test dependencies with Pipenv
                 Installing dependencies from Pipfile.lock \\(.+\\)...
                 Installing dependencies from Pipfile.lock \\(.+\\)...
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running post-compile hook
        REGEX
      end
    end
  end
end
