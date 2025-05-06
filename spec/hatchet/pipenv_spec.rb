# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Pipenv support' do
  context 'with a Pipfile.lock that is unchanged since the last build' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_basic', buildpacks:) }

    it 'builds with the specified python_version and re-uses packages from the cache' do
      app.deploy do |app|
        # TODO: We should not be leaking the Pipenv installation into the app environment.
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in Pipfile.lock
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
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
          remote:  '/app/.heroku/python/lib/python313.zip',
          remote:  '/app/.heroku/python/lib/python3.13',
          remote:  '/app/.heroku/python/lib/python3.13/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.13/site-packages'\\]
          remote: 
          remote: Package           Version
          remote: ----------------- -+
          remote: certifi           .+
          remote: distlib           .+
          remote: filelock          .+
          remote: pip               #{PIP_VERSION}
          remote: pipenv            #{PIPENV_VERSION}
          remote: platformdirs      .+
          remote: setuptools        .+
          remote: typing_extensions 4.12.2
          remote: virtualenv        .+
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.13/site-packages/typing_extensions.py'>
        REGEX
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in Pipfile.lock
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Inline app detected
        REGEX
      end
    end
  end

  # As well as testing the Pipfile.lock `python_full_version` field, this also tests:
  # 1. That `python_full_version` takes precedence over the `python_version` field.
  # 2. That Pipenv works on the oldest Python version supported by all stacks.
  # 3. That the security update available message works for Pipenv too.
  context 'with a Pipfile.lock containing python_full_version 3.9.0' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version') }

    it 'builds with the outdated Python version specified and displays a deprecation warning' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in Pipfile.lock
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
          remote:  !     changing the version in your Pipfile.lock file.
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
          remote:  !     Update your Pipfile.lock file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.9.0, and instead only specify
          remote:  !     the major Python version of 3.9 in your Pipfile.lock file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.9.0
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'when there is a both a Pipfile.lock python_version and a .python-version file' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_and_python_version_file') }

    it 'builds with the Python version from the .python-version file' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in .python-version
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock but no Python version specified' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 'builds with the default Python version' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote: 
          remote:  !     Warning: No Python version was specified.
          remote:  !     
          remote:  !     Your app doesn't specify a Python version and so the buildpack
          remote:  !     picked a default version for you.
          remote:  !     
          remote:  !     Relying on this default version isn't recommended, since it
          remote:  !     can change over time and may not be consistent with your local
          remote:  !     development environment, CI or other instances of your app.
          remote:  !     
          remote:  !     Please configure an explicit Python version for your app.
          remote:  !     
          remote:  !     Create a new file in the root directory of your app named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' character at the start of the
          remote:  !     filename. Don't add a file extension such as '.txt'.
          remote:  !     
          remote:  !     In the new file, specify your app's major Python version number
          remote:  !     only. Don't include quotes or a 'python-' prefix.
          remote:  !     
          remote:  !     For example, to request the latest version of Python #{DEFAULT_PYTHON_MAJOR_VERSION},
          remote:  !     update your .python-version file so it contains exactly:
          remote:  !     #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     If your app already has a .python-version file, check that it:
          remote:  !     
          remote:  !     1. Is in the top level directory \\(not a subdirectory\\).
          remote:  !     2. Is named exactly '.python-version' in all lowercase.
          remote:  !     3. Isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     4. Has been added to the Git repository using 'git add --all'
          remote:  !        and then committed using 'git commit'.
          remote:  !     
          remote:  !     In the future we will require the use of a .python-version
          remote:  !     file and this warning will be made an error.
          remote: 
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'without a Pipfile.lock' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_no_lockfile') }

    it 'builds with the default Python version using just the Pipfile' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: 
          remote:  !     Warning: No 'Pipfile.lock' found!
          remote:  !     
          remote:  !     A 'Pipfile' file was found, however, the associated 'Pipfile.lock'
          remote:  !     Pipenv lockfile was not. This means your app dependency versions
          remote:  !     aren't pinned, which means the package versions used on Heroku
          remote:  !     might not match those installed in other environments.
          remote:  !     
          remote:  !     For now, we will install your dependencies without a lockfile,
          remote:  !     however, in the future this warning will become an error.
          remote:  !     
          remote:  !     Run 'pipenv lock' locally to generate the lockfile, and make sure
          remote:  !     that 'Pipfile.lock' isn't listed in '.gitignore' or '.slugignore'.
          remote: 
          remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote: 
          remote:  !     Warning: No Python version was specified.
          remote:  !     
          remote:  !     Your app doesn't specify a Python version and so the buildpack
          remote:  !     picked a default version for you.
          remote:  !     
          remote:  !     Relying on this default version isn't recommended, since it
          remote:  !     can change over time and may not be consistent with your local
          remote:  !     development environment, CI or other instances of your app.
          remote:  !     
          remote:  !     Please configure an explicit Python version for your app.
          remote:  !     
          remote:  !     Create a new file in the root directory of your app named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' character at the start of the
          remote:  !     filename. Don't add a file extension such as '.txt'.
          remote:  !     
          remote:  !     In the new file, specify your app's major Python version number
          remote:  !     only. Don't include quotes or a 'python-' prefix.
          remote:  !     
          remote:  !     For example, to request the latest version of Python #{DEFAULT_PYTHON_MAJOR_VERSION},
          remote:  !     update your .python-version file so it contains exactly:
          remote:  !     #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     If your app already has a .python-version file, check that it:
          remote:  !     
          remote:  !     1. Is in the top level directory \\(not a subdirectory\\).
          remote:  !     2. Is named exactly '.python-version' in all lowercase.
          remote:  !     3. Isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     4. Has been added to the Git repository using 'git add --all'
          remote:  !        and then committed using 'git commit'.
          remote:  !     
          remote:  !     In the future we will require the use of a .python-version
          remote:  !     file and this warning will be made an error.
          remote: 
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --skip-lock'
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

  context 'with a Pipfile.lock containing invalid JSON' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_invalid_json', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        # The exact JQ error message varies between JQ versions, and thus across stacks.
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Can't parse Pipfile.lock.
          remote:  !     
          remote:  !     A Pipfile.lock file was found, however, it couldn't be parsed:
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
          remote:  !     Error: Invalid Python version in Pipfile.lock.
          remote:  !     
          remote:  !     The Python version specified in your Pipfile.lock file by the
          remote:  !     'python_version' or 'python_full_version' fields isn't valid.
          remote:  !     
          remote:  !     The following version was found:
          remote:  !     ^3.12
          remote:  !     
          remote:  !     However, the Python version must be specified as either:
          remote:  !     1. The major version only, for example: #{DEFAULT_PYTHON_MAJOR_VERSION} (recommended)
          remote:  !     2. An exact patch version, for example: #{DEFAULT_PYTHON_MAJOR_VERSION}.999
          remote:  !     
          remote:  !     Wildcards aren't supported.
          remote:  !     
          remote:  !     Please update your Pipfile to use a valid Python version and
          remote:  !     then run 'pipenv lock' to regenerate Pipfile.lock.
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://pipenv.pypa.io/en/stable/specifiers.html#specifying-versions-of-python
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
          remote:  !     Error: Invalid Python version in Pipfile.lock.
          remote:  !     
          remote:  !     The Python version specified in your Pipfile.lock file by the
          remote:  !     'python_version' or 'python_full_version' fields isn't valid.
          remote:  !     
          remote:  !     The following version was found:
          remote:  !     3.9.*
          remote:  !     
          remote:  !     However, the Python version must be specified as either:
          remote:  !     1. The major version only, for example: #{DEFAULT_PYTHON_MAJOR_VERSION} (recommended)
          remote:  !     2. An exact patch version, for example: #{DEFAULT_PYTHON_MAJOR_VERSION}.999
          remote:  !     
          remote:  !     Wildcards aren't supported.
          remote:  !     
          remote:  !     Please update your Pipfile to use a valid Python version and
          remote:  !     then run 'pipenv lock' to regenerate Pipfile.lock.
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://pipenv.pypa.io/en/stable/specifiers.html#specifying-versions-of-python
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing an EOL python_version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_eol', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~OUTPUT))
          remote: -----> Python app detected
          remote: -----> Using Python 3.8 specified in Pipfile.lock
          remote: 
          remote:  !     Error: The requested Python version has reached end-of-life.
          remote:  !     
          remote:  !     Python 3.8 has reached its upstream end-of-life, and is
          remote:  !     therefore no longer receiving security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, it's no longer supported by this buildpack:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote:  !     
          remote:  !     Please upgrade to at least Python 3.9 by changing the
          remote:  !     version in your Pipfile.lock file.
          remote:  !     
          remote:  !     If possible, we recommend upgrading all the way to Python #{DEFAULT_PYTHON_MAJOR_VERSION},
          remote:  !     since it contains many performance and usability improvements.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when the Pipenv and Python versions have changed since the last build' do
    # TODO: Bump this buildpack version the next time we update the Pipenv version.
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#archive/v253'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_basic', buildpacks:) }

    it 'clears the cache before installing' do
      app.deploy do |app|
        update_buildpacks(app, [:default])
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in Pipfile.lock
          remote: -----> Discarding cache since:
          remote:        - The Python version has changed from 3.12.4 to #{DEFAULT_PYTHON_FULL_VERSION}
          remote:        - The Pipenv version has changed from 2023.12.1 to #{PIPENV_VERSION}
          remote:        - The editable VCS repository location has changed \\(and Pipenv doesn't handle this correctly\\)
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Discovering process types
        REGEX
      end
    end
  end

  context 'when Pipfile contains editable requirements' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_editable', buildpacks:) }

    it 'rewrites .pth and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        _pipenv_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: _pipenv_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          __editable___local_package_setup_py_0_0_1_finder.py:/app/packages/local_package_setup_py/local_package_setup_py'}
          _pipenv_editable.pth:/app

          Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello setup.py!
          Running entrypoint for the VCS package: gunicorn (version 23.0.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Running bin/post_compile hook
          remote:        __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote:        _pipenv_editable.pth:/tmp/build_.+
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
          remote: -----> Inline app detected
          remote: __editable___gunicorn_23_0_0_finder.py:/app/.heroku/python/src/gunicorn/gunicorn'}
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: __editable___local_package_setup_py_0_0_1_finder.py:/tmp/build_.+/packages/local_package_setup_py/local_package_setup_py'}
          remote: _pipenv_editable.pth:/tmp/build_.+
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 23.0.0\\)
        REGEX
      end
    end
  end

  # This tests not only our handling of failing dependency installation, but also that we're running
  # Pipenv in such a way that it errors if the lockfile is out of sync, rather than simply updating it.
  context 'when the Pipfile.lock is out of sync with Pipfile' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Your Pipfile.lock \\(.+\\) is out of date.  Expected: \\(.+\\).
          remote:        .+
          remote:        ERROR:: Aborting deploy
          remote: 
          remote:  !     Error: Unable to install dependencies using Pipenv.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end
end
