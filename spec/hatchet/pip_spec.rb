# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'installs successfully using pip' do
  it 'installs successfully using pip' do
    app.deploy do |app|
      expect(app.output).to include("Installing dependencies using 'pip install -r requirements.txt'")
      expect(app.output).to include('Successfully installed')
    end
  end
end

RSpec.describe 'pip support' do
  context 'when requirements.txt is unchanged since the last build' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_basic', buildpacks:) }

    it 're-uses packages from the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 5))
          remote:          Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata (3.0 kB)
          remote:        Downloading typing_extensions-4.12.2-py3-none-any.whl (37 kB)
          remote:        Installing collected packages: typing-extensions
          remote:        Successfully installed typing-extensions-4.12.2
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
          remote: ['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python312.zip',
          remote:  '/app/.heroku/python/lib/python3.12',
          remote:  '/app/.heroku/python/lib/python3.12/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.12/site-packages']
          remote: 
          remote: Package           Version
          remote: ----------------- -------
          remote: pip               #{PIP_VERSION}
          remote: setuptools        #{SETUPTOOLS_VERSION}
          remote: typing_extensions 4.12.2
          remote: wheel             #{WHEEL_VERSION}
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.12/site-packages/typing_extensions.py'>
        OUTPUT
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote: -----> Inline app detected
        OUTPUT
      end
    end
  end

  context 'when requirements.txt has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_basic') }

    it 'clears the cache before installing the packages again' do
      app.deploy do |app|
        # The test fixture's requirements.txt is a symlink to a requirements file in a subdirectory in
        # order to test that symlinked requirements files work in general and with cache invalidation.
        File.write('requirements/prod.txt', 'six', mode: 'a')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The contents of requirements.txt changed
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 5))
          remote:          Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata (3.0 kB)
          remote:        Collecting six (from -r requirements.txt (line 6))
          remote:          Downloading six-1.16.0-py2.py3-none-any.whl.metadata (1.8 kB)
          remote:        Downloading typing_extensions-4.12.2-py3-none-any.whl (37 kB)
          remote:        Downloading six-1.16.0-py2.py3-none-any.whl (11 kB)
          remote:        Installing collected packages: typing-extensions, six
          remote:        Successfully installed six-1.16.0 typing-extensions-4.12.2
        OUTPUT
      end
    end
  end

  context 'when the package manager has changed from Pipenv to pip since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_basic') }

    it 'clears the cache before installing with pip' do
      app.deploy do |app|
        FileUtils.rm(['Pipfile', 'Pipfile.lock'])
        FileUtils.cp(FIXTURE_DIR.join('requirements_basic/.python-version'), '.')
        FileUtils.cp(FIXTURE_DIR.join('requirements_basic/requirements.txt'), '.')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The package manager has changed from pipenv to pip
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 5))
          remote:          Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata (3.0 kB)
          remote:        Downloading typing_extensions-4.12.2-py3-none-any.whl (37 kB)
          remote:        Installing collected packages: typing-extensions
          remote:        Successfully installed typing-extensions-4.12.2
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains popular compiled packages' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_compiled') }

    include_examples 'installs successfully using pip'
  end

  context 'when requirements.txt contains editable requirements (both VCS and local package)' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        easy-install.pth:/app/.heroku/src/gunicorn
          remote:        easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote:        local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
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
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Running bin/post_compile hook
          remote:        easy-install.pth:/app/.heroku/src/gunicorn
          remote:        easy-install.pth:/tmp/build_.*/packages/local_package_setup_py
          remote:        __editable___local_package_pyproject_toml_0_0_1_finder.py:/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'}
          remote:        gunicorn.egg-link:/app/.heroku/src/gunicorn
          remote:        local-package-setup-py.egg-link:/tmp/build_.*/packages/local_package_setup_py
          remote:        
          remote:        Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote:        Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote:        Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
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

  context 'when there is only a setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/setup_py_only') }

    it 'installs packages from setup.py' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install --editable .'
          remote:        Obtaining file:///tmp/build_.*
          remote:          Preparing metadata \\(setup.py\\): started
          remote:          Preparing metadata \\(setup.py\\): finished with status 'done'
          remote:        .+
          remote:        Installing collected packages: six, test
          remote:          Running setup.py develop for test
        REGEX
      end
    end
  end

  context 'when there is both a requirements.txt and setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_txt_and_setup_py') }

    it 'installs packages only from requirements.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting urllib3 (from -r requirements.txt (line 1))
        OUTPUT
        expect(app.output).not_to include('Running setup.py develop')
      end
    end
  end

  context 'when requirements.txt contains an invalid requirement' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_invalid', allow_failure: true) }

    it 'aborts the build and displays the pip error' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        ERROR: Invalid requirement: 'an-invalid-requirement!' (from line 1 of requirements.txt)
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
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_gdal', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:        note: This error originates from a subprocess, and is likely not a problem with pip.
          remote: 
          remote:  !     Error: Package installation failed since the GDAL library was not found.
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
end
