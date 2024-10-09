# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds with the requested Python version' do |requested_version|
  it "builds with Python #{requested_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python #{requested_version} specified in runtime.txt
        remote: -----> Installing Python #{requested_version}
        remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        remote: -----> Installing SQLite3
        remote: -----> Installing requirements with pip
        remote:        Collecting urllib3 (from -r requirements.txt (line 1))
      OUTPUT
      expect(app.run('python -V')).to include("Python #{requested_version}")
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
            remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          OUTPUT
        end
      end
    end

    context 'with an app last built using an older default Python version' do
      # This test performs an initial build using an older buildpack version, followed
      # by a build using the current version. This ensures that the current buildpack
      # can successfully read the version metadata written to the build cache in the past.
      let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v250'] }

      it 'builds with the same Python version as the last build' do
        app.deploy do |app|
          update_buildpacks(app, [:default])
          app.commit!
          app.push!
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> No Python version was specified. Using the same version as the last build: Python 3.12.3
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote:  !     A Python security update is available! Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_12}
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> No change in requirements detected, installing from cache
            remote: -----> Using cached install of Python 3.12.3
          OUTPUT
          expect(app.run('python -V')).to include('Python 3.12.3')
        end
      end
    end
  end

  context 'when runtime.txt contains python-2.7.18' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_2.7', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 2.7.18 specified in runtime.txt
          remote: 
          remote:  !     Error: The requested Python version has reached end-of-life.
          remote:  !     
          remote:  !     Python 2.7 has reached its upstream end-of-life, and is
          remote:  !     therefore no longer receiving security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, it is no longer supported by this buildpack.
          remote:  !     
          remote:  !     Please upgrade to a newer Python version by updating the
          remote:  !     version configured via the 'runtime.txt' file.
          remote:  !     
          remote:  !     For a list of the supported Python versions, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains python-3.7.17' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.7.17 specified in runtime.txt
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
          remote:  !     version configured via the 'runtime.txt' file.
          remote:  !     
          remote:  !     For a list of the supported Python versions, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains python-3.8.20' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'builds with Python 3.8.20 but shows a deprecation warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python #{LATEST_PYTHON_3_8} specified in runtime.txt
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
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3 (from -r requirements.txt (line 1))
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_8}")
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
            remote: -----> Using Python #{LATEST_PYTHON_3_8} specified in runtime.txt
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

  context 'when runtime.txt contains python-3.9.20' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when runtime.txt contains python-3.10.15' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'when runtime.txt contains python-3.11.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.11') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_11
  end

  context 'when runtime.txt contains python-3.12.7' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.12') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_12
  end

  context 'when runtime.txt contains an invalid Python version string' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_invalid', allow_failure: true) }

    it 'aborts the build with an invalid runtime.txt message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in runtime.txt.
          remote:  !     
          remote:  !     The Python version specified in 'runtime.txt' is not in
          remote:  !     the correct format.
          remote:  !     
          remote:  !     The following file contents were found:
          remote:  !     python-3.12.0invalid
          remote:  !     
          remote:  !     However, the version string must begin with a 'python-' prefix,
          remote:  !     followed by the version specified as '<major>.<minor>.<patch>'.
          remote:  !     Comments are not supported.
          remote:  !     
          remote:  !     For example, to request Python 3.12.7, use:
          remote:  !     python-3.12.7
          remote:  !     
          remote:  !     Please update 'runtime.txt' to use a valid version string, or
          remote:  !     else remove the file to instead use the default version
          remote:  !     (currently Python 3.12.7).
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains an non-existent Python major version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_non_existent_major', allow_failure: true) }

    it 'aborts the build with an invalid runtime.txt message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.999.0 specified in runtime.txt
          remote: 
          remote:  !     Error: The requested Python version is not recognised.
          remote:  !     
          remote:  !     The requested Python version 3.999 is not recognised.
          remote:  !     
          remote:  !     Check that this Python version has been officially released,
          remote:  !     and that the Python buildpack has added support for it:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
          remote:  !     
          remote:  !     If it has, make sure that you are using the latest version
          remote:  !     of this buildpack:
          remote:  !     https://devcenter.heroku.com/articles/python-support#checking-the-python-buildpack-version
          remote:  !     
          remote:  !     Otherwise, switch to a supported version (such as Python 3.12)
          remote:  !     by updating the version configured via the 'runtime.txt' file.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains a non-existent Python patch version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_non_existent_patch', allow_failure: true) }

    it 'aborts the build with a version not available message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.12.999 specified in runtime.txt
          remote: 
          remote:  !     Error: Python 3.12.999 is not available for this stack (#{app.stack}).
          remote:  !     
          remote:  !     For a list of the supported Python versions, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains stray whitespace' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_with_stray_whitespace') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_12
  end

  context 'when the requested Python version has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    it 'builds with the new Python version after removing the old install' do
      app.deploy do |app|
        File.write('runtime.txt', "python-#{LATEST_PYTHON_3_12}")
        app.commit!
        app.push!
        # TODO: The output shouldn't say "installing from cache", since it's not.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{LATEST_PYTHON_3_12} specified in runtime.txt
          remote: -----> Python version has changed from #{LATEST_PYTHON_3_9} to #{LATEST_PYTHON_3_12}, clearing cache
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing Python #{LATEST_PYTHON_3_12}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3 (from -r requirements.txt (line 1))
        OUTPUT
      end
    end
  end
end
