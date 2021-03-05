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
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
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
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
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
          remote: -----> Requirements file has been changed, clearing cached dependencies
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
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
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_editable') }

    # TODO: Make this test the path rewriting, and --src directory handling,
    # and that the packages work during all of hooks, later buildpacks, runtime,
    # and on subsequent builds (where the paths have to be migrated back).
    include_examples 'installs successfully using pip'
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

  context 'when using pysqlite and Python 2', stacks: %w[heroku-16 heroku-18] do
    # This is split out from the requirements_compiled fixture, since the original
    # pysqlite package (as opposed to the newer pysqlite3) only supports Python 2.
    # This test has to be skipped on newer stacks where Python 2 is not available.
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_pysqlite_python_2') }

    include_examples 'installs successfully using pip'
  end

  context 'when using Airflow 1.10.2 with SLUGIFY_USES_TEXT_UNIDECODE set' do
    let(:config) { { 'SLUGIFY_USES_TEXT_UNIDECODE' => 'yes' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_airflow_1.10.2', config: config) }

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
