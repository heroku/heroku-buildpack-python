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
          remote:        Resolved 7 packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.13.2
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/tmp/codon/tmp/cache/.heroku/python-uv:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PYTHONHASHSEED=random
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: UV_CACHE_DIR=/tmp/uv-cache
          remote: UV_NO_MANAGED_PYTHON=1
          remote: UV_PROJECT_ENVIRONMENT=/app/.heroku/python
          remote: UV_PYTHON_DOWNLOADS=never
          remote: 
          remote: \\['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python313.zip',
          remote:  '/app/.heroku/python/lib/python3.13',
          remote:  '/app/.heroku/python/lib/python3.13/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.13/site-packages'\\]
          remote: 
          remote: Using Python #{DEFAULT_PYTHON_FULL_VERSION} environment at: /app/.heroku/python
          remote: Package           Version
          remote: ----------------- -------
          remote: typing-extensions 4.13.2
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
          remote:        Resolved 7 packages in .+s
          remote:        Bytecode compiled 1 file in .+s
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
          remote:        Resolved 7 packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.13.2
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

    it 'rewrites .pth and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 5 packages in .+s
          remote:           .+
          remote:        Prepared 5 packages in .+s
          remote:        Installed 5 packages in .+s
          remote:        Bytecode compiled .+ files in .+s
          remote:         \\+ gunicorn==23.0.0 \\(from git\\+https://github.com/benoitc/gunicorn@a86ea1e4e6c271d1cd1823c7e14490123f9238fe\\)
          remote:         \\+ local-package-pyproject-toml==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_pyproject_toml\\)
          remote:         \\+ local-package-setup-py==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_setup_py\\)
          remote:         \\+ packaging==25.0
          remote:         \\+ uv-editable==0.0.0 \\(from file:///tmp/build_.+\\)
          remote: -----> Running bin/post_compile hook
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        uv_editable.pth:/tmp/build_.+/src
          remote:        
          remote:        Running entrypoint for the current package: Hello from uv-editable!
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: uv_editable.pth:/tmp/build_.+/src
          remote: 
          remote: Running entrypoint for the current package: Hello from uv-editable!
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          __editable___local_package_setup_py_0_0_1_finder.py:/app/packages/local_package_setup_py/local_package_setup_py'}
          uv_editable.pth:/app/src

          Running entrypoint for the current package: Hello from uv-editable!
          Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello from setup.py!
          Running entrypoint for the VCS package: gunicorn (version 23.0.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 5 packages in .+
          remote:           .+
          remote:        Prepared 3 packages in .+s
          remote:        Uninstalled 3 packages in .+s
          remote:        Installed 3 packages in .+s
          remote:        Bytecode compiled .+ files in .+s
          remote:         - local-package-pyproject-toml==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_pyproject_toml\\)
          remote:         \\+ local-package-pyproject-toml==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_pyproject_toml\\)
          remote:         - local-package-setup-py==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_setup_py\\)
          remote:         \\+ local-package-setup-py==0.0.1 \\(from file:///tmp/build_.+/packages/local_package_setup_py\\)
          remote:         - uv-editable==0.0.0 \\(from file:///tmp/build_.+\\)
          remote:         \\+ uv-editable==0.0.0 \\(from file:///tmp/build_.+\\)
          remote: -----> Running bin/post_compile hook
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        uv_editable.pth:/tmp/build_.+/src
          remote:        
          remote:        Running entrypoint for the current package: Hello from uv-editable!
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: uv_editable.pth:/tmp/build_.+/src
          remote: 
          remote: Running entrypoint for the current package: Hello from uv-editable!
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
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
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.13.2
        REGEX
      end
    end
  end

  # This tests the error message when there is no .python-version file, and in particular the case where
  # the buildpack's default Python version is not compatible with `requires-python` in pyproject.toml.
  # (Since we must prevent uv from downloading its own Python or using system Python, and also
  # want a clearer error message than using `--python` or `UV_PYTHON` would give us).
  context 'when there is no .python-version file' do
    context 'when there is no cached Python version' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/uv_no_python_version_file', allow_failure: true) }

      it 'fails the build with .python-version instructions' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote: 
            remote:  !     Error: No Python version was specified.
            remote:  !     
            remote:  !     When using the package manager uv on Heroku, you must specify
            remote:  !     your app's Python version with a .python-version file.
            remote:  !     
            remote:  !     To add a .python-version file:
            remote:  !     
            remote:  !     1. Make sure you are in the root directory of your app
            remote:  !        and not a subdirectory.
            remote:  !     2. Run 'uv python pin #{DEFAULT_PYTHON_MAJOR_VERSION}'
            remote:  !        (adjust to match your app's major Python version).
            remote:  !     3. Commit the changes to your Git repository using
            remote:  !        'git add --all' and then 'git commit'.
            remote:  !     
            remote:  !     Note: We strongly recommend that you don't specify the Python
            remote:  !     patch version number in your .python-version file, since it will
            remote:  !     pin your app to an exact Python version and so stop your app from
            remote:  !     receiving security updates each time it builds.
            remote: 
            remote:  !     Push rejected, failed to compile Python app.
          OUTPUT
        end
      end
    end

    context 'when there is a cached Python version' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', allow_failure: true) }

      it 'fails the build with .python-version instructions' do
        app.deploy do |app|
          FileUtils.rm('requirements.txt')
          FileUtils.cp(FIXTURE_DIR.join('uv_no_python_version_file/pyproject.toml'), '.')
          FileUtils.cp(FIXTURE_DIR.join('uv_no_python_version_file/uv.lock'), '.')
          app.commit!
          app.push!
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> No Python version was specified. Using the same major version as the last build: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote: 
            remote:  !     Error: No Python version was specified.
            remote:  !     
            remote:  !     When using the package manager uv on Heroku, you must specify
            remote:  !     your app's Python version with a .python-version file.
            remote:  !     
            remote:  !     To add a .python-version file:
            remote:  !     
            remote:  !     1. Make sure you are in the root directory of your app
            remote:  !        and not a subdirectory.
            remote:  !     2. Run 'uv python pin #{DEFAULT_PYTHON_MAJOR_VERSION}'
            remote:  !        (adjust to match your app's major Python version).
            remote:  !     3. Commit the changes to your Git repository using
            remote:  !        'git add --all' and then 'git commit'.
            remote:  !     
            remote:  !     Note: We strongly recommend that you don't specify the Python
            remote:  !     patch version number in your .python-version file, since it will
            remote:  !     pin your app to an exact Python version and so stop your app from
            remote:  !     receiving security updates each time it builds.
            remote: 
            remote:  !     Push rejected, failed to compile Python app.
          OUTPUT
        end
      end
    end
  end

  # This tests the error message when a runtime.txt is present, and in particular the case where
  # the runtime.txt version is not compatible with `requires-python` in pyproject.toml.
  # (Since we must prevent uv from downloading its own Python or using system Python, and also
  # want a clearer error message than using `--python` or `UV_PYTHON` would give us).
  context 'when there is a runtime.txt file' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_runtime_txt', allow_failure: true) }

    it 'fails the build with runtime.txt migration instructions' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Using Python 3.11 specified in runtime.txt
          remote: 
          remote:  !     Error: The runtime.txt file isn't supported when using uv.
          remote:  !     
          remote:  !     When using the package manager uv on Heroku, you must specify
          remote:  !     your app's Python version with a .python-version file and not
          remote:  !     a runtime.txt file.
          remote:  !     
          remote:  !     To switch to a .python-version file:
          remote:  !     
          remote:  !     1. Make sure you are in the root directory of your app
          remote:  !        and not a subdirectory.
          remote:  !     2. Delete your runtime.txt file.
          remote:  !     3. Run 'uv python pin 3.11'
          remote:  !        (adjust to match your app's major Python version).
          remote:  !     4. Commit the changes to your Git repository using
          remote:  !        'git add --all' and then 'git commit'.
          remote:  !     
          remote:  !     Note: We strongly recommend that you don't specify the Python
          remote:  !     patch version number in your .python-version file, since it will
          remote:  !     pin your app to an exact Python version and so stop your app from
          remote:  !     receiving security updates each time it builds.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # This tests the error message when `requires-python` in pyproject.toml isn't compatible with
  # the version in .python-version. This might seem unnecessary since it's testing something uv
  # validates itself, however, the quality of the error message here depends on what uv options
  # we use (for example, using `--python` or `UV_PYTHON` results in a worse error message).
  context 'when requires-python in pyproject.toml is incompatible with .python-version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_mismatched_python_version', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Using CPython #{DEFAULT_PYTHON_FULL_VERSION} interpreter at: /app/.heroku/python/bin/python#{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:        error: The Python request from `.python-version` resolved to Python #{DEFAULT_PYTHON_FULL_VERSION}, which is incompatible with the project's Python requirement: `==3.12.*`. Use `uv python pin` to update the `.python-version` file to a compatible version.
          remote: 
          remote:  !     Error: Unable to install dependencies using uv.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
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
          remote:        Resolved 2 packages in .+s
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
end
