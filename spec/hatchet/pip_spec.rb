# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'pip support' do
  context 'when requirements.txt is unchanged since the last build' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_basic', buildpacks:) }

    it 're-uses packages from the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 \\(from -r requirements.txt \\(line 5\\)\\)
          remote:          Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata \\(3.0 kB\\)
          remote:        Downloading typing_extensions-4.12.2-py3-none-any.whl \\(37 kB\\)
          remote:        Installing collected packages: typing-extensions
          remote:        Successfully installed typing-extensions-4.12.2
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
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
          remote: pip #{PIP_VERSION} from /app/.heroku/python/lib/python3.13/site-packages/pip \\(python 3.13\\)
          remote: Package           Version
          remote: ----------------- -------
          remote: pip               #{PIP_VERSION}
          remote: typing_extensions 4.12.2
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.13/site-packages/typing_extensions.py'>
          remote: 
          remote: {
          remote:   "cache_restore_duration": [0-9.]+,
          remote:   "cache_save_duration": [0-9.]+,
          remote:   "cache_status": "empty",
          remote:   "dependencies_install_duration": [0-9.]+,
          remote:   "django_collectstatic_duration": [0-9.]+,
          remote:   "nltk_downloader_duration": [0-9.]+,
          remote:   "package_manager": "pip",
          remote:   "package_manager_install_duration": [0-9.]+,
          remote:   "pip_version": "#{PIP_VERSION}",
          remote:   "post_compile_hook": false,
          remote:   "pre_compile_hook": false,
          remote:   "python_install_duration": [0-9.]+,
          remote:   "python_version": "#{DEFAULT_PYTHON_FULL_VERSION}",
          remote:   "python_version_major": "3.13",
          remote:   "python_version_origin": ".python-version",
          remote:   "python_version_outdated": false,
          remote:   "python_version_pinned": false,
          remote:   "python_version_requested": "3.13",
          remote:   "setup_py_only": false,
          remote:   "total_duration": [0-9.]+
          remote: }
        REGEX
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Requirement already satisfied: typing-extensions==4.12.2 (from -r requirements.txt (line 5)) (4.12.2)
          remote: -----> Saving cache
          remote: -----> Inline app detected
        OUTPUT
        # Test that pip is available at run-time too (since for historical reasons it's been
        # made available after the build, and users now rely on this).
        expect(app.run('pip --version')).to include("pip #{PIP_VERSION}")
      end
    end
  end

  context 'when requirements.txt has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_basic') }

    it 'clears the cache before installing the packages again' do
      app.deploy do |app|
        # The test fixture's requirements.txt is a symlink to a requirements file in a subdirectory in
        # order to test that symlinked requirements files work in general and with cache invalidation.
        File.write('requirements/prod.txt', 'six==1.17.0', mode: 'a')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The contents of requirements.txt changed
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 5))
          remote:          Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata (3.0 kB)
          remote:        Collecting six==1.17.0 (from -r requirements.txt (line 6))
          remote:          Downloading six-1.17.0-py2.py3-none-any.whl.metadata (1.7 kB)
          remote:        Downloading typing_extensions-4.12.2-py3-none-any.whl (37 kB)
          remote:        Downloading six-1.17.0-py2.py3-none-any.whl (11 kB)
          remote:        Installing collected packages: typing-extensions, six
          remote:        Successfully installed six-1.17.0 typing-extensions-4.12.2
          remote: -----> Saving cache
        OUTPUT
      end
    end
  end

  # This test intentionally uses Python 3.12, so that we test rewriting using older globally installed
  # setuptools (which causes .egg-link files to be created too). The Pipenv and Poetry equivalents of
  # this test covers the PEP-517/518 setuptools case.
  context 'when requirements.txt contains editable requirements (both VCS and local package)' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        easy-install.pth:/app/.heroku/python/src/gunicorn
          remote:        easy-install.pth:/tmp/build_.+/packages/local_package_setup_py
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        gunicorn.egg-link:/app/.heroku/python/src/gunicorn
          remote:        local-package-setup-py.egg-link:/tmp/build_.+/packages/local_package_setup_py
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: easy-install.pth:/app/.heroku/python/src/gunicorn
          remote: easy-install.pth:/tmp/build_.+/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/python/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.+/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints.sh')).to include(<<~OUTPUT)
          easy-install.pth:/app/.heroku/python/src/gunicorn
          easy-install.pth:/app/packages/local_package_setup_py
          __editable___local_package_pyproject_toml_0_0_1_finder.py:/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          gunicorn.egg-link:/app/.heroku/python/src/gunicorn
          local-package-setup-py.egg-link:/app/packages/local_package_setup_py

          Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello from setup.py!
          Running entrypoint for the VCS package: gunicorn (version 20.1.0)
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        easy-install.pth:/app/.heroku/python/src/gunicorn
          remote:        easy-install.pth:/tmp/build_.+/packages/local_package_setup_py
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        gunicorn.egg-link:/app/.heroku/python/src/gunicorn
          remote:        local-package-setup-py.egg-link:/tmp/build_.+/packages/local_package_setup_py
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: easy-install.pth:/app/.heroku/python/src/gunicorn
          remote: easy-install.pth:/tmp/build_.+/packages/local_package_setup_py
          remote: __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.+/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote: gunicorn.egg-link:/app/.heroku/python/src/gunicorn
          remote: local-package-setup-py.egg-link:/tmp/build_.+/packages/local_package_setup_py
          remote: 
          remote: Running entrypoint for the pyproject.toml-based local package: Hello from pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello from setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX
        # Test that the VCS repo checkout was cached correctly.
        expect(app.output).to include('Updating /app/.heroku/python/src/gunicorn clone (to revision 20.1.0)')
      end
    end
  end

  # This checks that the pip bootstrap works even with older bundled pip, and that our
  # chosen Pip version also supports our oldest supported Python version.
  context 'when using our oldest supported Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_oldest_python') }

    it 'installs successfully' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in runtime.txt
          remote: 
          remote:  !     Warning: The runtime.txt file is deprecated.
          remote:  !     
          remote:  !     The runtime.txt file is deprecated since it has been replaced
          remote:  !     by the more widely supported .python-version file:
          remote:  !     https://devcenter.heroku.com/changelog-items/3141
          remote:  !     
          remote:  !     Please switch to using a .python-version file instead.
          remote:  !     
          remote:  !     Delete your runtime.txt file and create a new file in the
          remote:  !     root directory of your app named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' character at the start of the
          remote:  !     filename. Don't add a file extension such as '.txt'.
          remote:  !     
          remote:  !     In the new file, specify your app's major Python version number
          remote:  !     only. Don't include quotes or a 'python-' prefix.
          remote:  !     
          remote:  !     For example, to request the latest version of Python 3.9,
          remote:  !     update your .python-version file so it contains exactly:
          remote:  !     3.9
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     In the future support for runtime.txt will be removed and
          remote:  !     this warning will be made an error.
          remote: 
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
          remote:  !     changing the version in your runtime.txt file.
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
          remote:  !     Update your runtime.txt file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.9.0, and instead only specify
          remote:  !     the major Python version of 3.9 in your runtime.txt file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.9.0
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.14.1 (from -r requirements.txt (line 2))
          remote:          Downloading typing_extensions-4.14.1-py3-none-any.whl.metadata (3.0 kB)
          remote:        Downloading typing_extensions-4.14.1-py3-none-any.whl (43 kB)
          remote:        Installing collected packages: typing-extensions
          remote:        Successfully installed typing-extensions-4.14.1
          remote: -----> Saving cache
        OUTPUT
        app.commit!
        app.push!
        # Test that our regex for cleaning up the "Requirement already satisfied" lines also works
        # with the relative paths output when pip is run with Python 3.10 and older. This and the
        # regex variant can be removed once support for Python 3.10 and older is dropped.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Requirement already satisfied: typing-extensions==4.14.1 (from -r requirements.txt (line 2)) (4.14.1)
          remote: -----> Saving cache
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains a package that needs compiling against the Python headers' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_compiled') }

    it 'installs successfully using pip' do
      app.deploy do |app|
        expect(app.output).to include('Building wheel for extension.dist')
      end
    end
  end

  context 'when requirements.txt contains an invalid requirement' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_invalid_requirement', allow_failure: true) }

    it 'aborts the build and displays the pip error' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        ERROR: Invalid requirement: 'an-invalid-requirement!': Expected end or semicolon (after name and no valid version specifier)
          remote:            an-invalid-requirement!
          remote:                                  ^ (from line 1 of requirements.txt)
          remote: 
          remote:  !     Error: Unable to install dependencies using pip.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains GDAL but the GDAL C++ library is missing' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_gdal', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:        note: This error originates from a subprocess, and is likely not a problem with pip.
          remote: 
          remote:  !     Error: Package installation failed since the GDAL library wasn't found.
          remote:  !     
          remote:  !     For GDAL, GEOS and PROJ support, use the Geo buildpack alongside the Python buildpack:
          remote:  !     https://github.com/heroku/heroku-geo-buildpack
          remote: 
          remote: 
          remote:  !     Error: Unable to install dependencies using pip.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains an old version of Celery with invalid metadata' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_legacy_celery', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:        ERROR: No matching distribution found for celery==5.2.0
          remote: 
          remote:  !     Error: One of your dependencies contains broken metadata.
          remote:  !     
          remote:  !     Newer versions of pip reject packages that use invalid versions
          remote:  !     in their metadata (such as Celery older than v5.2.1).
          remote:  !     
          remote:  !     Try upgrading to a newer version of the affected package.
          remote:  !     
          remote:  !     For more help, see:
          remote:  !     https://devcenter.heroku.com/changelog-items/3073
          remote: 
          remote: 
          remote:  !     Error: Unable to install dependencies using pip.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains pysqlite3' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_pysqlite3', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:        × Failed to build installable wheels for some pyproject.toml based projects
          remote:        ╰─> pysqlite3
          remote: 
          remote:  !     Error: Package installation failed since SQLite headers weren't found.
          remote:  !     
          remote:  !     The Python buildpack no longer installs the SQLite headers
          remote:  !     package since most apps don't require it.
          remote:  !     
          remote:  !     If you're trying to install the `pysqlite3` package, we
          remote:  !     recommend using the virtually identical `sqlite3` module in
          remote:  !     Python's standard library instead:
          remote:  !     https://docs.python.org/3/library/sqlite3.html
          remote:  !     
          remote:  !     To do this:
          remote:  !     1. Remove the `pysqlite3` package from your dependencies.
          remote:  !     2. Replace any `pysqlite3` imports in your app with `sqlite3`.
          remote:  !     
          remote:  !     Alternatively, if you can't use the `sqlite3` stdlib module,
          remote:  !     switch from the `pysqlite3` package to `pysqlite3-binary`,
          remote:  !     which is pre-compiled and doesn't need the SQLite headers to
          remote:  !     be installed.
          remote:  !     
          remote:  !     If instead you need the SQLite headers for another reason
          remote:  !     (or wish to continue to compile the `pysqlite3` package from
          remote:  !     source), then install the `libsqlite3-dev` and `libsqlite3-0`
          remote:  !     packages using the APT buildpack (make sure the APT buildpack
          remote:  !     runs before the Python buildpack, not after):
          remote:  !     https://github.com/heroku/heroku-buildpack-apt
          remote: 
          remote: 
          remote:  !     Error: Unable to install dependencies using pip.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end
end
