# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'uv support' do
  context 'with a uv.lock' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_basic', buildpacks:) }

    it 'installs successfully using uv and on rebuilds uses the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 7 packages in .+ms
          remote:        Prepared 1 package in .+ms
          remote:        Installed 1 package in .+ms
          remote:        Bytecode compiled 1 file in .+ms
          remote:         + typing-extensions==4.12.2
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/tmp/codon/tmp/cache/.heroku/python-uv:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PYTHONHASHSEED=random
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: UV_PROJECT_ENVIRONMENT=/app/.heroku/python
          remote: UV_PYTHON=/app/.heroku/python
          remote: UV_PYTHON_DOWNLOADS=never
          remote: UV_PYTHON_PREFERENCE=only-system
          remote: 
          remote: ['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python313.zip',
          remote:  '/app/.heroku/python/lib/python3.13',
          remote:  '/app/.heroku/python/lib/python3.13/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.13/site-packages']
          remote: 
          remote: Package           Version
          remote: ----------------- -------
          remote: typing-extensions 4.12.2
          remote: Using Python #{DEFAULT_PYTHON_FULL_VERSION} environment at: /app/.heroku/python
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.13/site-packages/typing_extensions.py'>
        REGEX
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Using cached uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 7 packages in .+ms
          remote:        Bytecode compiled 1 file in .+ms
          remote: -----> Inline app detected
        REGEX
      end
    end
  end

  # TODO: Enable this once a previous buildpack release exists that uses an older uv version.
  context 'when the uv version has changed since the last build',
          skip: 'requires prior buildpack release that uses older uv' do
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#vTODO'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_basic', buildpacks:) }

    it 'clears the cache before installing' do
      app.deploy do |app|
        update_buildpacks(app, [:default])
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The uv version has changed from TODO to #{UV_VERSION}
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 7 packages in .+ms
          remote:        Prepared 1 package in .+ms
          remote:        Installed 1 package in .+ms
          remote:        Bytecode compiled 1 file in .+ms
          remote:         + typing-extensions==4.12.2
          remote: -----> Discovering process types
        REGEX
      end
    end
  end

  # uv doesn't support editable mode with VCS dependencies, so unlike the editable tests for the other
  # package managers the gunicorn dependency isn't editable. However, we still include it to ensure we
  # have VCS coverage. See: https://github.com/astral-sh/uv/issues/5442
  context 'when uv.lock contains editable requirements and a VCS dependency' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        # TODO: Include the install output here, to test no hardlink warning + output when cache restored etc.
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        uv_editable.pth:/tmp/build_.+/src
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: uv_editable.pth:/tmp/build_.+/src
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          __editable___local_package_setup_py_0_0_1_finder.py:/app/packages/local_package_setup_py/local_package_setup_py'}
          uv_editable.pth:/app/src

          Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello setup.py!
          Running entrypoint for the VCS package: gunicorn (version 23.0.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        uv_editable.pth:/tmp/build_.+/src
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: uv_editable.pth:/tmp/build_.+/src
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX
      end
    end
  end

  context 'when using our oldest supported Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_oldest_python') }

    it 'installs successfully' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
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
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+ms
          remote:        Prepared 1 package in .+ms
          remote:        Installed 1 package in .+ms
          remote:        Bytecode compiled 1 file in .+ms
          remote:         + typing-extensions==4.12.2
        REGEX
      end
    end
  end

  # This tests not only our handling of failing dependency installation, but also that we're running
  # uv in such a way that it errors if the lockfile is out of sync, rather than simply updating it.
  context 'when uv.lock is out of sync with pyproject.toml' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+ms
          remote:        error: The lockfile at `uv.lock` needs to be updated, but `--locked` was provided. To update the lockfile, run `uv lock`.
          remote: 
          remote:  !     Error: Unable to install dependencies using uv.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  # TODO: Add a test for one or more of the following to ensure uv doesn't download it's own Python
  # or use distro Python, and that the error message is clear:
  #  - No .python-version file and a `requires-python` that conflicts with the default buildpack Python version.
  #  - runtime.txt file and a `requires-python` that conflicts with the version in it.
  #  - Some combination that matches distro Python and might otherwise use it.
  # What we do here depends on whether we make .python-version mandatory (see the comment for `UV_PYTHON` in uv.sh).
end
