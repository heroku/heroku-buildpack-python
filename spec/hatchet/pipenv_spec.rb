# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds using Pipenv with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      # TODO: Fix the "cp: cannot stat" error here and in the other testcases below (W-7924941).
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> Python app detected
        remote: -----> Using Python version specified in Pipfile.lock
        remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
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
        remote:  !     Requested runtime (python-#{requested_version}) is not available for this stack (#{app.stack}).
        remote:  !     Aborting.  More info: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Pipenv support' do
  context 'without a Pipfile.lock' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_no_lockfile') }

    it 'builds with the default Python version using just the Pipfile' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote:  !     No 'Pipfile.lock' found! We recommend you commit this into your repository.
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock but no Python version specified' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 'builds with the default Python version' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock \\(aad8b1\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing python_version 2.7' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_2.7', allow_failure: allow_failure) }

    context 'when using Heroku-18', stacks: %w[heroku-18] do
      it 'builds with the latest Python 2.7' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     Python 2 has reached its community EOL. Upgrade your Python runtime to maintain a secure application as soon as possible.
            remote:        Learn More: https://devcenter.heroku.com/articles/python-2-7-eol-faq
            remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
            remote: -----> Installing python-#{LATEST_PYTHON_2_7}
            remote: -----> Installing pip 20.3.4, setuptools 44.1.1 and wheel 0.37.1
            remote: -----> Installing dependencies with Pipenv 2020.11.15
            remote:        Installing dependencies from Pipfile.lock \\(b8efa9\\)...
            remote: -----> Installing SQLite3
          REGEX
        end
      end
    end

    context 'when using Heroku-20 or newer', stacks: %w[heroku-20 heroku-22] do
      let(:allow_failure) { true }

      # Python 2.7 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', LATEST_PYTHON_2_7
    end
  end

  # Python 3.5 isn't currently recognised in python_version, causing the default
  # Python version to be used instead, due to W-8104668.
  context 'with a Pipfile.lock containing python_version 3.5',
          skip: 'python_version mapping does not currently support 3.5' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.5') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_5
  end

  context 'with a Pipfile.lock containing python_version 3.6' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.6', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with the latest Python 3.6' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
            remote: -----> Installing python-#{LATEST_PYTHON_3_6}
            remote: -----> Installing pip 21.3.1, setuptools 59.6.0 and wheel 0.37.1
            remote: -----> Installing dependencies with Pipenv 2020.11.15
            remote:        Installing dependencies from Pipfile.lock \\(.*\\)...
            remote: -----> Installing SQLite3
          REGEX
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

  context 'with a Pipfile.lock containing python_full_version 3.10.0' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      it 'builds with the outdated Python version specified' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     Python has released a security update! Please consider upgrading to python-#{LATEST_PYTHON_3_10}
            remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
            remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
            remote: -----> Installing python-3.10.0
            remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
            remote: -----> Installing dependencies with Pipenv 2020.11.15
            remote:        Installing dependencies from Pipfile.lock \\(99d8c9\\)...
            remote: -----> Installing SQLite3
          REGEX
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Whilst Python 3.10 is supported on Heroku-22, only the latest version (3.10.4) has been built.
      # TODO: Once newer Python 3.10 versions are released, adjust this test to use 3.10.4,
      # which will work for all stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', '3.10.0'
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
          remote:  !     Requested runtime (^3.9) is not available for this stack (#{app.stack}).
          remote:  !     Aborting.  More info: https://devcenter.heroku.com/articles/python-support
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
          remote:  !     Requested runtime (python-X.Y.Z) is not available for this stack (#{app.stack}).
          remote:  !     Aborting.  More info: https://devcenter.heroku.com/articles/python-support
        OUTPUT
      end
    end
  end

  context 'when there is a both a Pipfile.lock python_version and a runtime.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_runtime_txt') }

    it 'builds with the Python version from runtime.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python version specified in runtime.txt
          remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Installing dependencies from Pipfile.lock \\(75eae0\\)...
          remote: -----> Installing SQLite3
        REGEX
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
          remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
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
          remote: cp: cannot stat '/tmp/build_.*/requirements.txt': No such file or directory
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 22.1.2, setuptools 60.10.0 and wheel 0.37.1
          remote: -----> Installing dependencies with Pipenv 2020.11.15
          remote:        Your Pipfile.lock \\(aad8b1\\) is out of date. Expected: \\(2d32e8\\).
          remote:        \\[DeployException\\]: .*
          remote:        ERROR:: Aborting deploy
        REGEX
      end
    end
  end
end
