# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Heroku CI' do
  let(:buildpacks) { [:default, 'heroku-community/inline'] }

  context 'when using pip' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_pip', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}
          -----> Installing dependencies using 'pip install -r requirements.txt -r requirements-test.txt'
                 .+
                 Successfully installed .+ pytest-.+ typing-extensions-.+
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
                 BUILD_DIR=/app
                 CACHE_DIR=/tmp/cache.+
                 CI=true
                 CPLUS_INCLUDE_PATH=/app/.heroku/python/include
                 C_INCLUDE_PATH=/app/.heroku/python/include
                 DISABLE_COLLECTSTATIC=1
                 ENV_DIR=/tmp/env.+
                 INSTALL_TEST=1
                 LANG=en_US.UTF-8
                 LC_ALL=C.UTF-8
                 LD_LIBRARY_PATH=/app/.heroku/python/lib
                 LIBRARY_PATH=/app/.heroku/python/lib
                 PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
                 PIP_DISABLE_PIP_VERSION_CHECK=1
                 PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
                 PYTHONUNBUFFERED=1
          -----> Saving cache

           !     Note: We recently added support for the package manager uv:
           !     https://devcenter.heroku.com/changelog-items/3238
           !     
           !     It's now our recommended Python package manager, since it
           !     supports lockfiles, is faster, gives more helpful error
           !     messages, and is actively maintained by a full-time team.
           !     
           !     If you haven't tried it yet, we suggest you take a look!
           !     https://docs.astral.sh/uv/

          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PIP_DISABLE_PIP_VERSION_CHECK=1
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
          PIP_DISABLE_PIP_VERSION_CHECK=1
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=5
          pytest .+
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Restoring cache
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing pip #{PIP_VERSION}
          -----> Installing dependencies using 'pip install -r requirements.txt -r requirements-test.txt'
                 Requirement already satisfied: typing-extensions==.+
                 Requirement already satisfied: pytest==.+
                 .+
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
        REGEX
      end
    end
  end

  context 'when using Pipenv' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_pipenv', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing Pipenv #{PIPENV_VERSION}
          -----> Installing dependencies using 'pipenv install --deploy --dev'
                 Installing dependencies from Pipfile.lock \\(.+\\)...
                 Installing dependencies from Pipfile.lock \\(.+\\)...
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
                 BUILD_DIR=/app
                 CACHE_DIR=/tmp/cache.+
                 CI=true
                 CPLUS_INCLUDE_PATH=/app/.heroku/python/include
                 C_INCLUDE_PATH=/app/.heroku/python/include
                 DISABLE_COLLECTSTATIC=1
                 ENV_DIR=/tmp/env.+
                 INSTALL_TEST=1
                 LANG=en_US.UTF-8
                 LC_ALL=C.UTF-8
                 LD_LIBRARY_PATH=/app/.heroku/python/lib
                 LIBRARY_PATH=/app/.heroku/python/lib
                 PATH=/app/.heroku/python/pipenv/bin:/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
                 PIPENV_SYSTEM=1
                 PIPENV_VERBOSITY=-1
                 PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
                 PYTHONUNBUFFERED=1
                 VIRTUAL_ENV=/app/.heroku/python
          -----> Saving cache

           !     Note: We recently added support for the package manager uv:
           !     https://devcenter.heroku.com/changelog-items/3238
           !     
           !     It's now our recommended Python package manager, since it
           !     supports lockfiles, is faster, gives more helpful error
           !     messages, and is actively maintained by a full-time team.
           !     
           !     If you haven't tried it yet, we suggest you take a look!
           !     https://docs.astral.sh/uv/

          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/app/.heroku/python/pipenv/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PIPENV_SYSTEM=1
          PIPENV_VERBOSITY=-1
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          VIRTUAL_ENV=/app/.heroku/python
          -----> No test-setup command provided. Skipping.
          -----> Running test command `./bin/print-env-vars.sh && pytest --version`...
          CI=true
          DYNO_RAM=2560
          FORWARDED_ALLOW_IPS=\\*
          GUNICORN_CMD_ARGS=--access-logfile -
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/app/.heroku/python/pipenv/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/:/app/.sprettur/bin/
          PIPENV_SYSTEM=1
          PIPENV_VERBOSITY=-1
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          VIRTUAL_ENV=/app/.heroku/python
          WEB_CONCURRENCY=5
          pytest .+
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Restoring cache
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Using cached Pipenv #{PIPENV_VERSION}
          -----> Installing dependencies using 'pipenv install --deploy --dev'
                 Installing dependencies from Pipfile.lock \\(.+\\)...
                 Installing dependencies from Pipfile.lock \\(.+\\)...
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
        REGEX
      end
    end
  end

  context 'when using Poetry' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_poetry', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        # The Poetry install log output order is non-deterministic, hence the regex.
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing Poetry #{POETRY_VERSION}
          -----> Installing dependencies using 'poetry sync'
                 Installing dependencies from lock file
                 
                 Package operations: 6 installs, 0 updates, 0 removals
                 
                   .+
                   - Installing (pytest|typing-extensions) .+
                   - Installing (pytest|typing-extensions) .+
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
                 BUILD_DIR=/app
                 CACHE_DIR=/tmp/cache.+
                 CI=true
                 CPLUS_INCLUDE_PATH=/app/.heroku/python/include
                 C_INCLUDE_PATH=/app/.heroku/python/include
                 DISABLE_COLLECTSTATIC=1
                 ENV_DIR=/tmp/env.+
                 INSTALL_TEST=1
                 LANG=en_US.UTF-8
                 LC_ALL=C.UTF-8
                 LD_LIBRARY_PATH=/app/.heroku/python/lib
                 LIBRARY_PATH=/app/.heroku/python/lib
                 PATH=/tmp/cache\\w+/.heroku/python-poetry/bin:/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
                 PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
                 POETRY_VIRTUALENVS_CREATE=false
                 POETRY_VIRTUALENVS_USE_POETRY_PYTHON=true
                 PYTHONUNBUFFERED=1
          -----> Saving cache

           !     Note: We recently added support for the package manager uv:
           !     https://devcenter.heroku.com/changelog-items/3238
           !     
           !     It's now our recommended Python package manager, since it
           !     supports lockfiles, is faster, gives more helpful error
           !     messages, and is actively maintained by a full-time team.
           !     
           !     If you haven't tried it yet, we suggest you take a look!
           !     https://docs.astral.sh/uv/

          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/tmp/cache\\w+/.heroku/python-poetry/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          POETRY_VIRTUALENVS_CREATE=false
          POETRY_VIRTUALENVS_USE_POETRY_PYTHON=true
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
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=5
          pytest .+
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again
        expect(clean_output(test_run.output)).to include(<<~OUTPUT)
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Restoring cache
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing Poetry #{POETRY_VERSION}
          -----> Installing dependencies using 'poetry sync'
                 Installing dependencies from lock file
                 
                 No dependencies to install or update
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
        OUTPUT
      end
    end
  end

  context 'when using uv' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/ci_uv', buildpacks:) }

    it 'installs both normal and test dependencies and uses cache on subsequent runs' do
      app.run_ci do |test_run|
        # The uv install log output order is non-deterministic, hence the regex.
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Installing uv #{UV_VERSION}
          -----> Installing dependencies using 'uv sync --locked'
                 Resolved 8 packages in .+s
                 Prepared 6 packages in .+s
                 Installed 6 packages in .+s
                 Bytecode compiled .+ files in .+s
                  .+
                  \\+ (pytest|typing-extensions)==.+
                  \\+ (pytest|typing-extensions)==.+
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
                 BUILD_DIR=/app
                 CACHE_DIR=/tmp/cache.+
                 CI=true
                 CPLUS_INCLUDE_PATH=/app/.heroku/python/include
                 C_INCLUDE_PATH=/app/.heroku/python/include
                 DISABLE_COLLECTSTATIC=1
                 ENV_DIR=/tmp/env.+
                 INSTALL_TEST=1
                 LANG=en_US.UTF-8
                 LC_ALL=C.UTF-8
                 LD_LIBRARY_PATH=/app/.heroku/python/lib
                 LIBRARY_PATH=/app/.heroku/python/lib
                 PATH=/tmp/cache\\w+/.heroku/python-uv:/app/.heroku/python/bin::/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
                 PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
                 PYTHONUNBUFFERED=1
                 UV_NO_MANAGED_PYTHON=1
                 UV_PROJECT_ENVIRONMENT=/app/.heroku/python
                 UV_PYTHON_DOWNLOADS=never
          -----> Saving cache
          -----> Inline app detected
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/tmp/cache\\w+/.heroku/python-uv:/usr/local/bin:/usr/bin:/bin:/app/.sprettur/bin/
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          UV_NO_MANAGED_PYTHON=1
          UV_PROJECT_ENVIRONMENT=/app/.heroku/python
          UV_PYTHON_DOWNLOADS=never
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
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=5
          pytest .+
          -----> test command `./bin/print-env-vars.sh && pytest --version` completed successfully
        REGEX

        test_run.run_again
        expect(clean_output(test_run.output)).to match(Regexp.new(<<~REGEX))
          -----> Python app detected
          -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          -----> Restoring cache
          -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          -----> Using cached uv #{UV_VERSION}
          -----> Installing dependencies using 'uv sync --locked'
                 Resolved 8 packages in .+s
                 Bytecode compiled .+ files in .+s
          -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          -----> Running bin/post_compile hook
        REGEX
      end
    end
  end
end
