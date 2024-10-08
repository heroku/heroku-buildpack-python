# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds using Pipenv with the requested Python version' do |requested_version, resolved_version|
  it "builds with Python #{requested_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> Python app detected
        remote: -----> Using Python #{requested_version} specified in Pipfile.lock
        remote: -----> Installing Python #{resolved_version}
        remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        remote: -----> Installing Pipenv #{PIPENV_VERSION}
        remote: -----> Installing SQLite3
        remote: -----> Installing dependencies with Pipenv
        remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
      REGEX
    end
  end
end

RSpec.describe 'Pipenv support' do
  context 'without a Pipfile.lock' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_no_lockfile') }

    it 'builds with the default Python version using just the Pipfile' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote:  !     No 'Pipfile.lock' found! We recommend you commit this into your repository.
          remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        The flag --skip-lock has been reintroduced \\(but is not recommended\\).  Without 
          remote:        the lock resolver it is difficult to manage multiple package indexes, and hash 
          remote:        checking is not provided.  However it can help manage installs with current 
          remote:        deficiencies in locking across platforms.
          remote:        Pipfile.lock not found, creating...
          .+
          remote:        Installing dependencies from Pipfile...
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock but no Python version specified' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified', buildpacks:) }

    # TODO: Run this on Heroku-22 too, once it has also migrated to the new build infrastructure.
    # (Currently the test fails on the old infrastructure due to subtle differences in system PATH elements.)
    it 'builds with the default Python version', stacks: %w[heroku-20 heroku-24] do
      app.deploy do |app|
        # TODO: We should not be leaking the Pipenv installation into the app environment.
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PYTHONHASHSEED=random
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: 
          remote: \\['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python312.zip',
          remote:  '/app/.heroku/python/lib/python3.12',
          remote:  '/app/.heroku/python/lib/python3.12/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.12/site-packages'\\]
          remote: 
          remote: Package           Version
          remote: ----------------- ---------
          remote: certifi           .+
          remote: distlib           .+
          remote: filelock          .+
          remote: pip               #{PIP_VERSION}
          remote: pipenv            #{PIPENV_VERSION}
          remote: platformdirs      .+
          remote: setuptools        #{SETUPTOOLS_VERSION}
          remote: typing_extensions 4.12.2
          remote: virtualenv        .+
          remote: wheel             #{WHEEL_VERSION}
          remote: 
          remote: \\<module 'typing_extensions' from '/app/.heroku/python/lib/python3.12/site-packages/typing_extensions.py'\\>
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing an EOL python_version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.7', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~OUTPUT))
          remote: -----> Python app detected
          remote: -----> Using Python 3.7 specified in Pipfile.lock
          remote: 
          remote:  !     Error: The requested Python version has reached end-of-life.
          remote:  !     
          remote:  !     Python 3.7 has reached its upstream end-of-life, and is
          remote:  !     therefore no longer receiving security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, it is no longer supported by this buildpack.
          remote:  !     
          remote:  !     Please upgrade to a newer Python version by updating the
          remote:  !     version configured via the 'Pipfile.lock' file.
          remote:  !     
          remote:  !     For a list of the supported Python versions, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing python_version 3.8' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.8', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'builds with the latest Python 3.8 but shows a deprecation warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python 3.8 specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 3.8 will reach its upstream end-of-life in October 2024, at which
            remote:  !     point it will no longer receive security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Support for Python 3.8 will be removed from this buildpack on December 4th, 2024.
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing Python #{LATEST_PYTHON_3_8}
            remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
            remote: -----> Installing Pipenv #{PIPENV_VERSION}
            remote: -----> Installing SQLite3
            remote: -----> Installing dependencies with Pipenv
            remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          REGEX
        end
      end
    end

    context 'when using Heroku-22 or newer', stacks: %w[heroku-22 heroku-24] do
      let(:allow_failure) { true }

      # We only support Python 3.8 on Heroku-20 and older.
      it 'aborts the build with a version not available message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python 3.8 specified in Pipfile.lock
            remote: 
            remote:  !     Error: Python #{LATEST_PYTHON_3_8} is not available for this stack (#{app.stack}).
            remote:  !     
            remote:  !     For a list of the supported Python versions, see:
            remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
            remote: 
            remote:  !     Push rejected, failed to compile Python app.
          OUTPUT
        end
      end
    end
  end

  context 'with a Pipfile.lock containing python_version 3.9' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.9') }

    include_examples 'builds using Pipenv with the requested Python version', '3.9', LATEST_PYTHON_3_9
  end

  context 'with a Pipfile.lock containing python_version 3.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.10') }

    include_examples 'builds using Pipenv with the requested Python version', '3.10', LATEST_PYTHON_3_10
  end

  context 'with a Pipfile.lock containing python_version 3.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.11') }

    include_examples 'builds using Pipenv with the requested Python version', '3.11', LATEST_PYTHON_3_11
  end

  context 'with a Pipfile.lock containing python_version 3.12' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.12') }

    include_examples 'builds using Pipenv with the requested Python version', '3.12', LATEST_PYTHON_3_12
  end

  context 'with a Pipfile.lock containing python_version 3.13' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.13') }

    it 'builds with latest Python 3.13' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in Pipfile.lock
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  # As well as testing `python_full_version`, this also tests:
  # 1. That `python_full_version` takes precedence over `python_version`.
  # 2. That Pipenv works on the oldest Python version supported by all stacks.
  # 3. That the security update available message works for Pipenv too.
  context 'with a Pipfile.lock containing python_full_version 3.9.0' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version', allow_failure:) }

    it 'builds with the outdated Python version specified and displays a deprecation warning' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in Pipfile.lock
          remote:  !     
          remote:  !     A Python security update is available! Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_9}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote:  !     
          remote: -----> Installing Python 3.9.0
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing invalid JSON' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_invalid_json', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        # The exact JQ error message varies between JQ versions, and thus across stacks.
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Cannot parse Pipfile.lock.
          remote:  !     
          remote:  !     A Pipfile.lock file was found, however, it could not be parsed:
          remote:  !     (jq: )?parse error: Invalid numeric literal at line 1, column 8
          remote:  !     
          remote:  !     This is likely due to it not being valid JSON.
          remote:  !     
          remote:  !     Run 'pipenv lock' to regenerate/fix the lockfile.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing an invalid python_version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in Pipfile / Pipfile.lock.
          remote:  !     
          remote:  !     The Python version specified in Pipfile / Pipfile.lock by the
          remote:  !     'python_version' or 'python_full_version' field is not valid.
          remote:  !     
          remote:  !     The following version was found:
          remote:  !     ^3.12
          remote:  !     
          remote:  !     However, the version must be specified as either:
          remote:  !     1. '<major>.<minor>' (recommended, for automatic security updates)
          remote:  !     2. '<major>.<minor>.<patch>' (to pin to an exact Python version)
          remote:  !     
          remote:  !     Please update your 'Pipfile' to use a valid Python version and
          remote:  !     then run 'pipenv lock' to regenerate the lockfile.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://pipenv.pypa.io/en/latest/specifiers.html#specifying-versions-of-python
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing an invalid python_full_version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in Pipfile / Pipfile.lock.
          remote:  !     
          remote:  !     The Python version specified in Pipfile / Pipfile.lock by the
          remote:  !     'python_version' or 'python_full_version' field is not valid.
          remote:  !     
          remote:  !     The following version was found:
          remote:  !     3.9.*
          remote:  !     
          remote:  !     However, the version must be specified as either:
          remote:  !     1. '<major>.<minor>' (recommended, for automatic security updates)
          remote:  !     2. '<major>.<minor>.<patch>' (to pin to an exact Python version)
          remote:  !     
          remote:  !     Please update your 'Pipfile' to use a valid Python version and
          remote:  !     then run 'pipenv lock' to regenerate the lockfile.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://pipenv.pypa.io/en/latest/specifiers.html#specifying-versions-of-python
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when there is a both a Pipfile.lock python_version and a runtime.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_runtime_txt') }

    it 'builds with the Python version from runtime.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{LATEST_PYTHON_3_12} specified in runtime.txt
          remote: -----> Installing Python #{LATEST_PYTHON_3_12}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'when Pipfile.lock is unchanged since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 're-uses packages from the cache' do
      app.deploy do |app|
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Discovering process types
        REGEX
      end
    end
  end

  context 'when the package manager has changed from pip to Pipenv since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified') }

    # TODO: Fix this case so the cache is actually cleared.
    it 'clears the cache before installing with Pipenv' do
      app.deploy do |app|
        FileUtils.rm('requirements.txt')
        FileUtils.cp(FIXTURE_DIR.join('pipenv_python_version_unspecified/Pipfile'), '.')
        FileUtils.cp(FIXTURE_DIR.join('pipenv_python_version_unspecified/Pipfile.lock'), '.')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Discovering process types
        REGEX
      end
    end
  end

  context 'when there is both a Pipfile.lock and a requirements.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_requirements_txt') }

    it 'builds with Pipenv rather than pip' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.12 specified in Pipfile.lock
          remote: -----> Installing Python #{LATEST_PYTHON_3_12}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'when the Pipfile.lock is out of sync with Pipfile' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies with Pipenv
          remote:        Your Pipfile.lock \\(.+\\) is out of date.  Expected: \\(.+\\).
          remote:        .+
          remote:        ERROR:: Aborting deploy
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  context 'when Pipfile contains editable requirements' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Running post-compile hook
          remote: easy-install.pth:/app/.heroku/src/gunicorn
          remote: easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: easy-install.pth:/app/.heroku/src/gunicorn
          remote: easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          easy-install.pth:/app/.heroku/src/gunicorn
          easy-install.pth:/app/packages/local_package_setup_py
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          gunicorn.egg-link:/app/.heroku/src/gunicorn
          local-package-setup-py.egg-link:/app/packages/local_package_setup_py

          Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello setup.py!
          Running entrypoint for the VCS package: gunicorn (version 20.1.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Running post-compile hook
          remote: easy-install.pth:/app/.heroku/src/gunicorn
          remote: easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: easy-install.pth:/app/.heroku/src/gunicorn
          remote: easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX
      end
    end
  end
end
