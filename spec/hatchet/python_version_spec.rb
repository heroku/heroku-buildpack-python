# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip 22.2.2, setuptools 63.4.3 and wheel 0.37.1
        remote: -----> Installing SQLite3
        remote: -----> Installing requirements with pip
        remote:        Collecting urllib3
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
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks: buildpacks) }

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

  context 'when runtime.txt contains python-2.7.18' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_2.7', allow_failure: allow_failure) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'builds with Python 2.7.18' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 2 reached upstream end-of-life on January 1st, 2020, and is
            remote:  !     therefore no longer receiving security updates. Upgrade to Python 3
            remote:  !     as soon as possible to keep your app secure.
            remote:  !     
            remote:  !     In addition, Python 2 is only supported on our oldest stack, Heroku-18,
            remote:  !     which is deprecated and reaches end-of-life on April 30th, 2023.
            remote:  !     
            remote:  !     See: https://devcenter.heroku.com/articles/python-2-7-eol-faq
            remote:  !     
            remote: -----> Installing python-#{LATEST_PYTHON_2_7}
            remote: -----> Installing pip 20.3.4, setuptools 44.1.1 and wheel 0.37.1
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_2_7}")
        end
      end
    end

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      let(:allow_failure) { true }

      # Python 2.7 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_2_7}"
    end
  end

  context 'when runtime.txt contains python-3.4.10' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.4', allow_failure: allow_failure) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'builds with Python 3.4.10' do
        app.deploy do |app|
          # The Pip deprecation warning is due to the newest Pip that works on Python 3.4
          # not supporting the `PIP_NO_PYTHON_VERSION_WARNING` env var.
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 3.4 reached upstream end-of-life on March 18th, 2019, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
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

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      let(:allow_failure) { true }

      # Python 3.4 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_4}"
    end
  end

  context 'when runtime.txt contains python-3.5.10' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.5', allow_failure: allow_failure) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'builds with Python 3.5.10' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 3.5 reached upstream end-of-life on September 30th, 2020, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing python-#{LATEST_PYTHON_3_5}
            remote: -----> Installing pip 20.3.4, setuptools 50.3.2 and wheel 0.37.1
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_5}")
        end
      end
    end

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      let(:allow_failure) { true }

      # Python 3.5 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_5}"
    end
  end

  context 'when runtime.txt contains python-3.6.15' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with Python 3.6.15' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     Python 3.6 reached upstream end-of-life on December 23rd, 2021, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing python-#{LATEST_PYTHON_3_6}
            remote: -----> Installing pip 21.3.1, setuptools 59.6.0 and wheel 0.37.1
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_6}")
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.6 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_6}"
    end
  end

  context 'when runtime.txt contains python-3.7.14' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'builds with the requested Python version', LATEST_PYTHON_3_7
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.7 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_7}"
    end
  end

  context 'when runtime.txt contains python-3.8.14' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'builds with the requested Python version', LATEST_PYTHON_3_8
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.8 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message', "python-#{LATEST_PYTHON_3_8}"
    end
  end

  context 'when runtime.txt contains python-3.9.14' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'when runtime.txt contains python-3.10.7' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10') }

    include_examples 'builds with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'when runtime.txt contains pypy2.7-7.3.2' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_2.7', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with PyPy2.7 v7.3.2' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     PyPy support is deprecated and the versions available on Heroku are outdated and insecure.
            remote:  !     Please switch to one of the supported CPython versions by updating your runtime.txt.
            remote:  !     See: https://devcenter.heroku.com/articles/python-support
            remote:  !     
            remote: -----> Installing pypy2.7-#{LATEST_PYPY_2_7}
            remote: -----> Installing pip 20.3.4, setuptools 44.1.1 and wheel 0.37.1
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include('Python 2.7', "PyPy #{LATEST_PYPY_2_7}")
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # The beta PyPy support is deprecated and so not being made available for new stacks.
      include_examples 'aborts the build with a runtime not available message', "pypy2.7-#{LATEST_PYPY_2_7}"
    end
  end

  context 'when runtime.txt contains pypy3.6-7.3.2' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_3.6', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with PyPy3.6 v7.3.2' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
            remote:  !     
            remote:  !     PyPy support is deprecated and the versions available on Heroku are outdated and insecure.
            remote:  !     Please switch to one of the supported CPython versions by updating your runtime.txt.
            remote:  !     See: https://devcenter.heroku.com/articles/python-support
            remote:  !     
            remote: -----> Installing pypy3.6-#{LATEST_PYPY_3_6}
            remote: -----> Installing pip 21.3.1, setuptools 59.6.0 and wheel 0.37.1
            remote: -----> Installing SQLite3
            remote: -----> Installing requirements with pip
            remote:        Collecting urllib3
          OUTPUT
          expect(app.run('python -V')).to include('Python 3.6', "PyPy #{LATEST_PYPY_3_6}")
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # The beta PyPy support is deprecated and so not being made available for new stacks.
      include_examples 'aborts the build with a runtime not available message', "pypy3.6-#{LATEST_PYPY_3_6}"
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
          remote: -----> Installing pip 22.2.2, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
      end
    end
  end
end
