# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'installs successfully using pip' do
  it 'installs successfully using pip' do
    app.deploy do |app|
      expect(app.output).to include('Installing requirements with pip')
      expect(app.output).to include('Successfully installed')
    end
  end
end

RSpec.describe 'Pip support' do
  context 'when requirements.txt is unchanged since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified') }

    it 're-uses packages from the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3 \\(from -r requirements.txt \\(line 1\\)\\)
          remote:          Downloading urllib3-.*
          remote:        Downloading urllib3-.*
          remote:        Installing collected packages: urllib3
          remote:        Successfully installed urllib3-.*
        REGEX
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Using cached install of python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote: -----> Discovering process types
        OUTPUT
      end
    end
  end

  context 'when requirements.txt has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified') }

    it 'clears the cache before installing the packages again' do
      app.deploy do |app|
        File.write('requirements.txt', 'six', mode: 'a')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Requirements file has been changed, clearing cached dependencies
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3 \\(from -r requirements.txt \\(line 1\\)\\)
          remote:          Downloading urllib3-.*
          remote:        Collecting six \\(from -r requirements.txt \\(line 2\\)\\)
          remote:          Downloading six-.*
          remote:        Downloading urllib3-.*
          remote:        Downloading six-.*
          remote:        Installing collected packages: urllib3, six
          remote:        Successfully installed six-.* urllib3-.*
        REGEX
      end
    end
  end

  context 'when requirements.txt contains popular compiled packages' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_compiled') }

    include_examples 'installs successfully using pip'
  end

  context 'when requirements.txt contains Git requirements URLs' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_git') }

    include_examples 'installs successfully using pip'
  end

  context 'when requirements.txt contains editable requirements' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_editable', buildpacks:) }

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
        expect(app.run('bin/test-entrypoints')).to include(<<~OUTPUT)
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

  context 'when there is only a setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/setup_py_only') }

    it 'installs packages from setup.py' do
      app.deploy do |app|
        expect(app.output).to include('Running setup.py develop for test')
        expect(app.output).to include('Successfully installed six')
      end
    end
  end

  context 'when there is both a requirements.txt and setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_txt_and_setup_py') }

    it 'installs packages only from requirements.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3 (from -r requirements.txt (line 1))
        OUTPUT
        expect(app.output).not_to include('Running setup.py develop')
      end
    end
  end

  context 'when requirements.txt contains GDAL but the GDAL C++ library is missing' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_gdal', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Hello! Package installation failed since the GDAL library was not found.
          remote:  !     For GDAL, GEOS and PROJ support, use the Geo buildpack alongside the Python buildpack:
          remote:  !     https://github.com/heroku/heroku-geo-buildpack
        OUTPUT
      end
    end
  end
end
