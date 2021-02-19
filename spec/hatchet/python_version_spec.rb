# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
        remote: -----> Installing SQLite3
        remote: -----> Installing requirements with pip
        remote:        Collecting urllib3
      OUTPUT
      expect(app.run('python -V')).to include("Python #{python_version}")
    end
  end
end

RSpec.shared_examples 'aborts the build with a runtime not available message' do |requested_version|
  it 'aborts the build with a runtime not available message' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote:  !     Requested runtime (python-#{requested_version}) is not available for this stack (#{app.stack}).
        remote:  !     Aborting.  More info: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Python version support' do
  context 'when no Python version is specified' do
    let(:buildpacks) { [:default] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks: buildpacks) }

    context 'with a new app' do
      it 'builds with the default Python version' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          OUTPUT
        end
      end
    end

    context 'with an app last built using an older default Python version' do
      # This test performs an initial build using an older buildpack version, followed
      # by a build using the current version. This ensures that the current buildpack
      # can successfully read the version metadata written to the build cache in the past.
      let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v189'] }

      it 'builds with the same Python version as the last build' do
        app.deploy do |app|
          update_buildpacks(app, [:default])
          app.commit!
          app.push!
          # TODO: The build log should explain that sticky-versioning has occurred,
          # so that users know why their app is on an older Python version.
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote:  !     Python has released a security update! Please consider upgrading to python-#{LATEST_PYTHON_3_6}
            remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
          OUTPUT
          expect(app.run('python -V')).to include('Python 3.6.12')
        end
      end
    end
  end

  context 'when runtime.txt contains python-2.7.18' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_2.7', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      it 'builds with Python 2.7.18' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote:  !     Python 2 has reached it's community EOL. Upgrade your Python runtime to maintain a secure application as soon as possible.
            remote:        Learn More: https://devcenter.heroku.com/articles/python-2-7-eol-faq
            remote: -----> Installing python-#{LATEST_PYTHON_2_7}
            remote: -----> Installing pip 20.1.1, setuptools 44.1.1 and wheel 0.34.2
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_2_7}")
        end
      end
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      # Python 2.7 is EOL, so it has not been built for Heroku-20.
      include_examples 'aborts the build with a runtime not available message', LATEST_PYTHON_2_7
    end
  end

  context 'when runtime.txt contains python-3.4.10' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.4', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      it 'builds with Python 3.4.10' do
        app.deploy do |app|
          # The Pip deprecation warning is due to the newest Pip that works on Python 3.4
          # not supporting the `PIP_NO_PYTHON_VERSION_WARNING` env var.
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Installing python-#{LATEST_PYTHON_3_4}
            remote: -----> Installing pip 19.1.1, setuptools 43.0.0 and wheel 0.33.6
            remote: DEPRECATION: Python 3.4 support has been deprecated. pip 19.1 will be the last one supporting it. Please upgrade your Python as Python 3.4 won't be maintained after March 2019 \\(cf PEP 429\\).
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        DEPRECATION: Python 3.4 support has been deprecated. pip 19.1 will be the last one supporting it. Please upgrade your Python as Python 3.4 won't be maintained after March 2019 \\(cf PEP 429\\).
            remote:        Collecting urllib3 \\(from -r /tmp/build_.*/requirements.txt \\(line 1\\)\\)
          REGEX
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_4}")
        end
      end
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      # Python 3.4 is EOL, so it has not been built for Heroku-20.
      include_examples 'aborts the build with a runtime not available message', LATEST_PYTHON_3_4
    end
  end

  context 'when runtime.txt contains python-3.5.10' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.5', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      include_examples 'builds with the requested Python version', LATEST_PYTHON_3_5
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      # Python 3.5 is EOL, so it has not been built for Heroku-20.
      include_examples 'aborts the build with a runtime not available message', LATEST_PYTHON_3_5
    end
  end

  context 'when runtime.txt contains python-3.6.13' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_6
  end

  context 'when runtime.txt contains python-3.7.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_7
  end

  context 'when runtime.txt contains python-3.8.8' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_8
  end

  context 'when runtime.txt contains python-3.9.2' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when runtime.txt contains pypy2.7-7.3.2' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_2.7') }

    it 'builds with PyPy2.7 v7.3.2' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Installing pypy2.7-#{LATEST_PYPY_2_7}
          remote: -----> Installing pip 20.1.1, setuptools 44.1.1 and wheel 0.34.2
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
        expect(app.run('python -V')).to include('Python 2.7', "PyPy #{LATEST_PYPY_2_7}")
      end
    end
  end

  context 'when runtime.txt contains pypy3.6-7.3.2' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_3.6') }

    it 'builds with PyPy3.6 v7.3.2' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Installing pypy3.6-#{LATEST_PYPY_3_6}
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
        expect(app.run('python -V')).to include('Python 3.6', "PyPy #{LATEST_PYPY_3_6}")
      end
    end
  end

  context 'when runtime.txt contains an invalid python version string' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_invalid', allow_failure: true) }

    include_examples 'aborts the build with a runtime not available message', 'X.Y.Z'
  end

  context 'when runtime.txt contains stray whitespace' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_with_stray_whitespace') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when there is only a runtime.txt and no requirements.txt', skip: 'not currently supported (W-8720280)' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_only', allow_failure: true) }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when the requested Python version has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6') }

    it 'builds with the new Python version after removing the old install' do
      app.deploy do |app|
        File.write('runtime.txt', "python-#{LATEST_PYTHON_3_9}")
        app.commit!
        app.push!
        # TODO: The output shouldn't say "installing from cache", since it's not.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Found python-#{LATEST_PYTHON_3_6}, removing
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing python-#{LATEST_PYTHON_3_9}
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
      end
    end
  end
end
