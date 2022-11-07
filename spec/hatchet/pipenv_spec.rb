# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds using Pipenv with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> Python app detected
        remote: -----> Using Python version specified in Pipfile.lock
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
        remote: -----> Installing dependencies with Pipenv 2020.11.15
        remote:        Installing dependencies from Pipfile.lock \\(.*\\)...
        remote: -----> Installing SQLite3
      REGEX
    end
  end
end

RSpec.shared_examples 'aborts the build with a runtime not available message (Pipenv)' do |requested_version|
  it 'aborts the build with a runtime not available message' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in Pipfile.lock
        remote:  !     Requested runtime 'python-#{requested_version}' is not available for this stack (#{app.stack}).
        remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Pipenv support' do
  context 'without a Pipfile.lock' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_no_lockfile') }

    it 'builds with the default Python version using just the Pipfile' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote:  !     No 'Pipfile.lock' found! We recommend you commit this into your repository.
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock but no Python version specified' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 'builds with the default Python version' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock (aad8b1)...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing python_version 2.7' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_2.7', allow_failure: true) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'aborts the build with an EOL message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 2 reached upstream end-of-life on January 1st, 2020, and is
            remote:  !     therefore no longer receiving security updates. Apps still using it
            remote:  !     contain potential security vulnerabilities and should be upgraded to
            remote:  !     Python 3 as soon as possible.
            remote:  !     
            remote:  !     In addition, Python 2 is only supported on our oldest stack, Heroku-18,
            remote:  !     which is deprecated and reaches end-of-life on April 30th, 2023.
            remote:  !     
            remote:  !     As such, it is no longer supported by the latest version of this buildpack:
            remote:  !     https://devcenter.heroku.com/changelog-items/2473
            remote:  !     
            remote:  !     You must either:
            remote:  !       - Upgrade to Python 3 (recommended)
            remote:  !       - Switch to the container stack and use the upstream legacy 'python:2.7' Docker images
            remote:  !       - Switch to an older version of the Python buildpack (short term workaround only)
            remote:  !     
            remote:  !     For more details, see:
            remote:  !     https://devcenter.heroku.com/articles/python-2-7-eol-faq
            remote:  !     
          OUTPUT
        end
      end
    end

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      # Python 2.7 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', '2.7.18'
    end
  end

  context 'with a Pipfile.lock containing python_version 3.5' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.5', allow_failure: true) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'aborts the build with an EOL message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 3.5 reached upstream end-of-life on September 30th, 2020, and is
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

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      # Python 3.5 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', '3.5.10'
    end
  end

  context 'with a Pipfile.lock containing python_version 3.6' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.6', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with the latest Python 3.6' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
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
            remote: -----> Installing dependencies with Pipenv 2020.11.15
            remote:        Installing dependencies from Pipfile.lock (b8b71b)...
            remote: -----> Installing SQLite3
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.6 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', LATEST_PYTHON_3_6
    end
  end

  context 'with a Pipfile.lock containing python_version 3.7' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.7', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_7
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.7 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', LATEST_PYTHON_3_7
    end
  end

  context 'with a Pipfile.lock containing python_version 3.8' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.8', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_8
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.8 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', LATEST_PYTHON_3_8
    end
  end

  context 'with a Pipfile.lock containing python_version 3.9' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.9') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'with a Pipfile.lock containing python_version 3.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.10') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'with a Pipfile.lock containing python_version 3.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.11') }

    it 'builds with the latest Python 3.11' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote: -----> Installing python-#{LATEST_PYTHON_3_11}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        /tmp/build_.*/.heroku/python/lib/python3.11/site-packages/pipenv/vendor/attr/_make.py:778: RuntimeWarning: Running interpreter doesn't sufficiently support code object introspection. .*
          remote:          set_closure_cell\\(cell, cls\\)
          remote:        Installing dependencies from Pipfile.lock \\(.*\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing python_full_version 3.10.4' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version', allow_failure: allow_failure) }

    it 'builds with the outdated Python version specified' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     
          remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{LATEST_PYTHON_3_10}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote:  !     
          remote: -----> Installing python-3.10.4
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock (e047bc)...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing an invalid python_version',
          skip: 'unknown python_version values are currently ignored (W-8104668)' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     Requested runtime '^3.9' is not available for this stack (#{app.stack}).
          remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
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
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     Requested runtime 'python-X.Y.Z' is not available for this stack (#{app.stack}).
          remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
        OUTPUT
      end
    end
  end

  context 'when there is a both a Pipfile.lock python_version and a runtime.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_runtime_txt') }

    it 'builds with the Python version from runtime.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in runtime.txt
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock (75eae0)...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'when there is both a Pipfile.lock and a requirements.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_requirements_txt') }

    it 'builds with Pipenv rather than pip' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock (2d32e8)...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'when the Pipfile.lock is out of sync with Pipfile' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.3.1, setuptools 63.4.3 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Your Pipfile.lock \\(aad8b1\\) is out of date. Expected: \\(2d32e8\\).
          remote:        \\[DeployException\\]: .*
          remote:        ERROR:: Aborting deploy
        REGEX
      end
    end
  end
end
