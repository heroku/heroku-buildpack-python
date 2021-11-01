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
          remote: -----> Installing pip 21.3.1, setuptools 57.5.0 and wheel 0.37.0
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
          remote:          Downloading urllib3-.*
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
          remote: -----> Installing pip 21.3.1, setuptools 57.5.0 and wheel 0.37.0
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
          remote: -----> Installing pip 21.3.1, setuptools 57.5.0 and wheel 0.37.0
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
          remote:          Downloading urllib3-.*
          remote:        Collecting six
          remote:          Downloading six-.*
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

  context 'when requirements.txt contains Git/Mercurial requirements URLs' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_vcs') }

    include_examples 'installs successfully using pip'
  end

  context 'when requirements.txt contains editable requirements' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_editable', buildpacks: buildpacks) }

    it 'rewrites .pth and .egg-link paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed gunicorn-20.1.0 local-package-0.0.1
          remote: -----> Running post-compile hook
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /tmp/build_.*/local_package
          remote: /app/.heroku/src/gunicorn
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local-package.egg-link <==
          remote: /tmp/build_.*/local_package
          remote: .
          remote: Running entrypoint for the local package: Hello!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /tmp/build_.*/local_package
          remote: /app/.heroku/src/gunicorn
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local-package.egg-link <==
          remote: /tmp/build_.*/local_package
          remote: .
          remote: Running entrypoint for the local package: Hello!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints')).to match(Regexp.new(<<~REGEX))
          ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          .*

          ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          /app/local_package
          /app/.heroku/src/gunicorn

          ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          /app/.heroku/src/gunicorn
          .
          ==> .heroku/python/lib/python.*/site-packages/local-package.egg-link <==
          /app/local_package
          .
          Running entrypoint for the local package: Hello!
          Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed gunicorn-20.1.0 local-package-0.0.1
          remote: -----> Running post-compile hook
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /app/.heroku/src/gunicorn
          remote: /tmp/build_.*/local_package
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local-package.egg-link <==
          remote: /tmp/build_.*/local_package
          remote: .
          remote: Running entrypoint for the local package: Hello!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /app/.heroku/src/gunicorn
          remote: /tmp/build_.*/local_package
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local-package.egg-link <==
          remote: /tmp/build_.*/local_package
          remote: .
          remote: Running entrypoint for the local package: Hello!
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
          remote:        Collecting urllib3
        OUTPUT
        expect(app.output).not_to include('Running setup.py develop')
      end
    end
  end

  context 'when using pysqlite and Python 2', stacks: %w[heroku-18] do
    # This is split out from the requirements_compiled fixture, since the original
    # pysqlite package (as opposed to the newer pysqlite3) only supports Python 2.
    # This test has to be skipped on newer stacks where Python 2 is not available.
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_pysqlite_python_2') }

    include_examples 'installs successfully using pip'
  end

  context 'when requirements.txt contains GDAL but the GDAL C++ library is missing' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_gdal', allow_failure: true) }

    it 'outputs instructions for how to resolve the build failure' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     Hello! Package installation failed since the GDAL library was not found.
          remote:  !     For GDAL, GEOS and PROJ support, use the Geo buildpack alongside the Python buildpack:
          remote:  !     https://github.com/heroku/heroku-geo-buildpack
          remote:  !       -- Much Love, Heroku.
        OUTPUT
      end
    end
  end

  context 'when the legacy BUILD_WITH_GEO_LIBRARIES env var is set' do
    let(:config) { { 'BUILD_WITH_GEO_LIBRARIES' => '' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', config: config, allow_failure: true) }

    it 'aborts the build with an unsupported error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote:  !     The Python buildpack's legacy BUILD_WITH_GEO_LIBRARIES functonality is
          remote:  !     no longer supported:
          remote:  !     https://devcenter.heroku.com/changelog-items/1947
        OUTPUT
      end
    end
  end
end
