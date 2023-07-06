# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        remote: -----> Installing SQLite3
        remote: -----> Installing requirements with pip
        remote:        Collecting urllib3 (from -r requirements.txt (line 1))
      OUTPUT
      expect(app.run('python -V')).to include("Python #{python_version}")
    end
  end
end

RSpec.shared_examples 'aborts the build with a runtime not available message' do |requested_runtime|
  it 'aborts the build with a runtime not available message' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote:  !     Requested runtime '#{requested_runtime}' is not available for this stack (#{app.stack}).
        remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Python version support' do
  context 'when no Python version is specified' do
    let(:buildpacks) { [:default] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks:) }

    context 'with a new app' do
      it 'builds with the default Python version' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          OUTPUT
        end
      end
    end

    context 'with an app last built using an older default Python version' do
      # This test performs an initial build using an older buildpack version, followed
      # by a build using the current version. This ensures that the current buildpack
      # can successfully read the version metadata written to the build cache in the past.
      let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v213'] }

      it 'builds with the same Python version as the last build' do
        app.deploy do |app|
          update_buildpacks(app, [:default])
          app.commit!
          app.push!
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> No Python version was specified. Using the same version as the last build: python-3.10.5
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{LATEST_PYTHON_3_10}
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> No change in requirements detected, installing from cache
            remote: -----> Using cached install of python-3.10.5
          OUTPUT
          expect(app.run('python -V')).to include('Python 3.10.5')
        end
      end
    end
  end

  context 'when runtime.txt contains python-3.6.15' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6', allow_failure: true) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'aborts the build with an EOL message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 3.6 reached upstream end-of-life on December 23rd, 2021, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     As such, it is no longer supported by the latest version of this buildpack.
            remote:  !     
            remote:  !     Please upgrade to a newer Python version. See:
            remote:  !     https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      # Python 3.6 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', 'python-3.6.15'
    end
  end

  context 'when runtime.txt contains python-3.7.17' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'builds with Python 3.7.17 but shows a deprecation warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 3.7 reached its upstream end-of-life on June 27th, 2023, so no longer
            remote:  !     receives any security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Support for Python 3.7 will be removed from this buildpack in October 2023.
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing python-#{LATEST_PYTHON_3_7}
            remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3 (from -r requirements.txt (line 1))
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_7}")
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.7 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_7}"
    end
  end

  context 'when runtime.txt contains python-3.8.17' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      include_examples 'builds with the requested Python version', LATEST_PYTHON_3_8
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.8 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_8}"
    end
  end

  context 'when runtime.txt contains python-3.9.17' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when runtime.txt contains python-3.10.12' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'when runtime.txt contains python-3.11.4' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.11') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_11
  end

  context 'when runtime.txt contains pypy3.6-7.3.2' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_3.6', allow_failure: true) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'aborts the build with a sunset message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     PyPy is no longer supported by the latest version of this buildpack.
            remote:  !     
            remote:  !     Please switch to one of the supported CPython versions by updating your
            remote:  !     runtime.txt file. See:
            remote:  !     https://devcenter.heroku.com/articles/python-support
            remote:  !     
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      # The beta PyPy support is deprecated and so not being made available for new stacks.
      include_examples 'aborts the build with a runtime not available message', 'pypy3.6-7.3.2'
    end
  end

  context 'when runtime.txt contains an invalid python version string' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_invalid', allow_failure: true) }

    include_examples 'aborts the build with a runtime not available message', 'python-X.Y.Z'
  end

  context 'when runtime.txt contains stray whitespace' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_with_stray_whitespace') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'when there is only a runtime.txt and no requirements.txt', skip: 'not currently supported (W-8720280)' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_only', allow_failure: true) }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'when the requested Python version has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    it 'builds with the new Python version after removing the old install' do
      app.deploy do |app|
        File.write('runtime.txt', "python-#{LATEST_PYTHON_3_10}")
        app.commit!
        app.push!
        # TODO: The output shouldn't say "installing from cache", since it's not.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in runtime.txt
          remote: -----> Python version has changed from python-#{LATEST_PYTHON_3_9} to python-#{LATEST_PYTHON_3_10}, clearing cache
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3 (from -r requirements.txt (line 1))
        OUTPUT
      end
    end
  end
end
