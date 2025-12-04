# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Poetry support' do
  context 'with a poetry.lock' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_basic', buildpacks:) }

    it 'installs successfully using Poetry and on rebuilds uses the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions \\(4.15.0\\)
          remote: -----> Running bin/post_compile hook
          remote:        BUILD_DIR=/tmp/build_.+
          remote:        CACHE_DIR=/tmp/codon/tmp/cache
          remote:        C_INCLUDE_PATH=/app/.heroku/python/include
          remote:        CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote:        ENV_DIR=/tmp/.+
          remote:        LANG=en_US.UTF-8
          remote:        LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote:        LIBRARY_PATH=/app/.heroku/python/lib
          remote:        PATH=/tmp/codon/tmp/cache/.heroku/python-poetry/bin:/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote:        PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote:        POETRY_VIRTUALENVS_CREATE=false
          remote:        POETRY_VIRTUALENVS_USE_POETRY_PYTHON=true
          remote:        PYTHONUNBUFFERED=1
          remote: -----> Saving cache
          remote: 
          remote:  !     Note: We recently added support for the package manager uv:
          remote:  !     https://devcenter.heroku.com/changelog-items/3238
          remote:  !     
          remote:  !     It's now our recommended Python package manager, since it
          remote:  !     supports lockfiles, is faster, gives more helpful error
          remote:  !     messages, and is actively maintained by a full-time team.
          remote:  !     
          remote:  !     If you haven't tried it yet, we suggest you take a look!
          remote:  !     https://docs.astral.sh/uv/
          remote: 
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/tmp/codon/tmp/cache/.heroku/python-poetry/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: POETRY_VIRTUALENVS_CREATE=false
          remote: POETRY_VIRTUALENVS_USE_POETRY_PYTHON=true
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: 
          remote: \\['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python314.zip',
          remote:  '/app/.heroku/python/lib/python3.14',
          remote:  '/app/.heroku/python/lib/python3.14/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.14/site-packages'\\]
          remote: 
          remote: Poetry \\(version #{POETRY_VERSION}\\)
          remote: Skipping virtualenv creation, as specified in config file.
          remote: typing-extensions 4.15.0 Backported and Experimental Type Hints for Python ...
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.14/site-packages/typing_extensions.py'>
          remote: 
          remote: \\{
          remote:   "cache_restore_duration": [0-9.]+,
          remote:   "cache_save_duration": [0-9.]+,
          remote:   "cache_status": "empty",
          remote:   "dependencies_install_duration": [0-9.]+,
          remote:   "django_collectstatic_duration": [0-9.]+,
          remote:   "nltk_downloader_duration": [0-9.]+,
          remote:   "package_manager": "poetry",
          remote:   "package_manager_install_duration": [0-9.]+,
          remote:   "poetry_version": "#{POETRY_VERSION}",
          remote:   "post_compile_hook": true,
          remote:   "post_compile_hook_duration": [0-9.]+,
          remote:   "pre_compile_hook": false,
          remote:   "python_install_duration": [0-9.]+,
          remote:   "python_version": "#{DEFAULT_PYTHON_FULL_VERSION}",
          remote:   "python_version_major": "3.14",
          remote:   "python_version_origin": ".python-version",
          remote:   "python_version_outdated": false,
          remote:   "python_version_pinned": false,
          remote:   "python_version_requested": "3.14",
          remote:   "total_duration": [0-9.]+
          remote: \\}
        REGEX

        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Using cached Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        No dependencies to install or update
          remote: -----> Running bin/post_compile hook
          remote:        .+
          remote: -----> Saving cache
        REGEX

        command = 'bin/print-env-vars.sh && if command -v poetry; then echo "Poetry unexpectedly found!" && exit 1; fi'
        expect(app.run(command)).to eq(<<~OUTPUT)
          DYNO_RAM=512
          FORWARDED_ALLOW_IPS=*
          GUNICORN_CMD_ARGS=--access-logfile -
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=2
        OUTPUT
        expect($CHILD_STATUS.exitstatus).to eq(0)
      end
    end
  end

  # TODO: Rename this test description back this when the Poetry version next changes.
  context 'when the Python version has changed since the last build' do
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v313'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_basic', buildpacks:) }

    it 'clears the cache before installing' do
      app.deploy do |app|
        update_buildpacks(app, [:default])
        FileUtils.rm('bin/post_compile')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.14 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The Python version has changed from 3.14.0 to #{LATEST_PYTHON_3_14}
          remote: -----> Installing Python #{LATEST_PYTHON_3_14}
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.15.0)
          remote: -----> Saving cache
        OUTPUT
      end
    end
  end

  context 'when poetry.lock contains editable requirements (both VCS and local package)' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_editable', buildpacks:) }

    it 'rewrites .pth and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 4 installs, 0 updates, 0 removals
          remote:        
          remote:          - Installing packaging \\(25.0\\)
          remote:          - Installing gunicorn \\(23.0.0 56b5ad8\\)
          remote:          - Installing local-package-pyproject-toml \\(0.0.1 /tmp/build_.+/packages/local_package_pyproject_toml\\)
          remote:          - Installing local-package-setup-py \\(0.0.1 /tmp/build_.+/packages/local_package_setup_py\\)
          remote:        
          remote:        Installing the current project: poetry-editable \\(0.0.1\\)
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        poetry_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the current package: Hello from poetry-editable!
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Saving cache
          .+
          remote: -----> Inline app detected
          remote: __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: poetry_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the current package: Hello from poetry-editable!
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          __editable___local_package_setup_py_0_0_1_finder.py:/app/packages/local_package_setup_py/local_package_setup_py'}
          poetry_editable.pth:/app

          Running entrypoint for the current package: Hello from poetry-editable!
          Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello from setup.py!
          Running entrypoint for the VCS package: gunicorn (version 23.0.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 0 installs, 3 updates, 0 removals
          remote:        
          remote:          - Updating gunicorn \\(23.0.0 /app/.heroku/python/src/gunicorn -> 23.0.0 56b5ad8\\)
          remote:          - Updating local-package-pyproject-toml \\(0.0.1 /tmp/build_.+/packages/local_package_pyproject_toml -> 0.0.1 /tmp/build_.+/packages/local_package_pyproject_toml\\)
          remote:          - Updating local-package-setup-py \\(0.0.1 /tmp/build_.+/packages/local_package_setup_py -> 0.0.1 /tmp/build_.+/packages/local_package_setup_py\\)
          remote:        
          remote:        Installing the current project: poetry-editable \\(0.0.1\\)
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        poetry_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the current package: Hello from poetry-editable!
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Saving cache
          .+
          remote: -----> Inline app detected
          remote: __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: poetry_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the current package: Hello from poetry-editable!
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX
      end
    end
  end

  # This checks that the Poetry bootstrap works even with older bundled pip, and that our
  # chosen Poetry version also supports our oldest supported Python version. The fixture
  # also includes a `brotli` directory to test the workaround for an `ensurepip` bug in
  # older Python versions: https://github.com/heroku/heroku-buildpack-python/issues/1697
  context 'when using our oldest supported Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_oldest_python') }

    it 'installs successfully' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in .python-version
          remote: 
          remote:  !     Warning: Support for Python 3.9 is ending soon!
          remote:  !     
          remote:  !     Python 3.9 reached its upstream end-of-life on 31st October 2025,
          remote:  !     and so no longer receives security updates:
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
          remote:  !     Warning: A Python patch update is available!
          remote:  !     
          remote:  !     Your app is using Python 3.9.0, however, there is a newer
          remote:  !     patch release of Python 3.9 available: #{LATEST_PYTHON_3_9}
          remote:  !     
          remote:  !     It is important to always use the latest patch version of
          remote:  !     Python to keep your app secure.
          remote:  !     
          remote:  !     Update your .python-version file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.9.0, and instead only specify
          remote:  !     the major Python version of 3.9 in your .python-version file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.9.0
          remote: -----> Installing Poetry #{POETRY_VERSION}
          remote: -----> Installing dependencies using 'poetry sync --only main'
          remote:        Installing dependencies from lock file
          remote:        
          remote:        Package operations: 1 install, 0 updates, 0 removals
          remote:        
          remote:          - Installing typing-extensions (4.15.0)
          remote: -----> Saving cache
        OUTPUT
      end
    end
  end

  # This is disabled since it's currently broken upstream: https://github.com/python-poetry/poetry/issues/10226
  # This tests that Poetry doesn't download its own Python or fall back to system Python
  # if the Python version in pyproject.toml doesn't match that in .python-version.
  # context 'when requires-python in pyproject.toml is incompatible with .python-version' do
  #   let(:app) { Hatchet::Runner.new('spec/fixtures/poetry_mismatched_python_version', allow_failure: true) }
  #
  #   it 'fails the build' do
  #     app.deploy do |app|
  #       expect(clean_output(app.output)).to include(<<~OUTPUT)
  #         remote: -----> Installing dependencies using 'poetry sync --only main'
  #         remote:        <TODO whatever error message Poetry displays if they fix their bug>
  #       OUTPUT
  #     end
  #   end
  # end

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
end
