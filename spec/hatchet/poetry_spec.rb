# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Poetry support' do
  context 'with a poetry.lock' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_basic', buildpacks:) }

    it 'installs successfully using Poetry and on rebuilds uses the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.12.2)
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/tmp/codon/tmp/cache/.heroku/python-poetry/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: POETRY_VIRTUALENVS_CREATE=false
          remote: PYTHONHASHSEED=random
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: 
          remote: ['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python313.zip',
          remote:  '/app/.heroku/python/lib/python3.13',
          remote:  '/app/.heroku/python/lib/python3.13/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.13/site-packages']
          remote: 
          remote: Skipping virtualenv creation, as specified in config file.
          remote: typing-extensions 4.12.2 Backported and Experimental Type Hints for Python ...
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.13/site-packages/typing_extensions.py'>
        OUTPUT
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Using cached Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        No dependencies to install or update
          remote: -----> Inline app detected
        OUTPUT
      end
    end
  end

  context 'when the requested Python version has changed since the last build' do
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v268'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_basic', buildpacks:) }

    it 'clears the cache before installing' do
      app.deploy do |app|
        update_buildpacks(app, [:default])
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The Python version has changed from 3.13.0 to #{LATEST_PYTHON_3_13}
          remote:        - The Poetry version has changed from 1.8.4 to #{POETRY_VERSION}
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.12.2)
          remote: -----> Discovering process types
        OUTPUT
      end
    end
  end

  context 'when the package manager has changed from pip to Poetry since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_basic') }

    it 'clears the cache before installing with Poetry' do
      app.deploy do |app|
        FileUtils.rm('requirements.txt')
        FileUtils.cp(FIXTURE_DIR.join('poetry_basic/pyproject.toml'), '.')
        FileUtils.cp(FIXTURE_DIR.join('poetry_basic/poetry.lock'), '.')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The package manager has changed from pip to poetry
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.12.2)
          remote: -----> Discovering process types
        OUTPUT
      end
    end
  end

  context 'when poetry.lock contains editable requirements (both VCS and local package)' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_20_1_0_finder.py:/tmp/build_.+/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        poetry_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: __editable___gunicorn_20_1_0_finder.py:/tmp/build_.+/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: poetry_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          __editable___gunicorn_20_1_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          __editable___local_package_setup_py_0_0_1_finder.py:/app/packages/local_package_setup_py/local_package_setup_py'}
          poetry_editable.pth:/app

          Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello setup.py!
          Running entrypoint for the VCS package: gunicorn (version 20.1.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_20_1_0_finder.py:/tmp/build_.+/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        poetry_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: __editable___gunicorn_20_1_0_finder.py:/tmp/build_.+/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: poetry_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX
      end
    end
  end

  # This checks that the Poetry bootstrap works even with older bundled pip, and that our
  # chosen Poetry version also supports our oldest supported Python version. The fixture
  # also includes a `brotli` directory to test the workaround for an `ensurepip` bug in
  # older Python versions: https://github.com/heroku/heroku-buildpack-python/issues/1697
  context 'when using the oldest supported Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_oldest_python') }

    it 'installs successfully' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in .python-version
          remote: -----> Installing Python 3.9.0
          remote: 
          remote:  !     Warning: Support for Python 3.9 is ending soon!
          remote:  !     
          remote:  !     Python 3.9 will reach its upstream end-of-life in October 2025,
          remote:  !     at which point it will no longer receive security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, support for Python 3.9 will be removed from this
          remote:  !     buildpack on 7th January 2026.
          remote:  !     
          remote:  !     Upgrade to a newer Python version as soon as possible, by
          remote:  !     changing the version in your .python-version file.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote: 
          remote: 
          remote:  !     Warning: A Python security update is available!
          remote:  !     
          remote:  !     Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_9}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote: 
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.12.2)
        OUTPUT
      end
    end
  end

  # This tests not only our handling of failing dependency installation, but also that we're running
  # Poetry in such a way that it errors if the lockfile is out of sync, rather than simply updating it.
  context 'when poetry.lock is out of sync with pyproject.toml' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        pyproject.toml changed significantly since poetry.lock was last generated. Run `poetry lock` to fix the lock file.
          remote: 
          remote:  !     Error: Unable to install dependencies using Poetry.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # This case will be turned into an error in the future, but for now is required for backwards compatibility.
  context 'when there is both a poetry.lock and a requirements.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_txt_and_poetry_lock') }

    it 'build using pip rather than Poetry' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Warning: Multiple Python package manager files were found.
          remote:  !     
          remote:  !     Exactly one package manager file should be present in your app's
          remote:  !     source code, however, several were found:
          remote:  !     
          remote:  !     requirements.txt (pip)
          remote:  !     poetry.lock (Poetry)
          remote:  !     
          remote:  !     For now, we will build your app using the first package manager
          remote:  !     listed above, however, in the future this warning will become
          remote:  !     an error.
          remote:  !     
          remote:  !     Decide which package manager you want to use with your app, and
          remote:  !     then delete the file(s) and any config from the others.
          remote: 
          remote: 
          remote:  !     Note: We recently added support for the package manager Poetry.
          remote:  !     If you are using a third-party Poetry buildpack you must remove
          remote:  !     it, otherwise the requirements.txt file it generates will cause
          remote:  !     the warning above.
          remote: 
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
        OUTPUT
      end
    end
  end
end
