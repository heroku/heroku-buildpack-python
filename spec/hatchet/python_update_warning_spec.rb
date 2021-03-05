# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'warns there is a Python update available' do |requested_version, latest_version|
  it 'warns there is a Python update available' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote:  !     Python has released a security update! Please consider upgrading to python-#{latest_version}
        remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
        remote: -----> Installing python-#{requested_version}
      OUTPUT
    end
  end
end

RSpec.shared_examples 'aborts the build without showing an update warning' do |requested_version|
  it 'aborts the build without showing an update warning' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote:  !     Requested runtime (python-#{requested_version}) is not available for this stack (#{app.stack}).
        remote:  !     Aborting.  More info: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Python update warnings' do
  context 'with a runtime.txt containing python-2.7.17' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_2.7_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      it 'warns that Python 2.7.17 is both EOL and not the latest patch release' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote:  !     Python 2 has reached it's community EOL. Upgrade your Python runtime to maintain a secure application as soon as possible.
            remote:        Learn More: https://devcenter.heroku.com/articles/python-2-7-eol-faq
            remote:  !     Only the latest version of Python 2 is supported on the platform. Please consider upgrading to python-#{LATEST_PYTHON_2_7}
            remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
            remote: -----> Installing python-2.7.17
          OUTPUT
        end
      end
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '2.7.17'
    end
  end

  context 'with a runtime.txt containing python-3.4.9' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.4_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      include_examples 'warns there is a Python update available', '3.4.9', LATEST_PYTHON_3_4
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '3.4.9'
    end
  end

  context 'with a runtime.txt containing python-3.5.9' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.5_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-16 or Heroku-18', stacks: %w[heroku-16 heroku-18] do
      include_examples 'warns there is a Python update available', '3.5.9', LATEST_PYTHON_3_5
    end

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '3.5.9'
    end
  end

  context 'with a runtime.txt containing python-3.6.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6_outdated') }

    include_examples 'warns there is a Python update available', '3.6.11', LATEST_PYTHON_3_6
  end

  context 'with a runtime.txt containing python-3.7.8' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7_outdated') }

    include_examples 'warns there is a Python update available', '3.7.8', LATEST_PYTHON_3_7
  end

  context 'with a runtime.txt containing python-3.8.6' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8_outdated') }

    include_examples 'warns there is a Python update available', '3.8.6', LATEST_PYTHON_3_8
  end

  context 'with a runtime.txt containing python-3.9.0' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9_outdated') }

    include_examples 'warns there is a Python update available', '3.9.0', LATEST_PYTHON_3_9
  end

  context 'with a runtime.txt containing pypy2.7-7.3.1' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_2.7_outdated') }

    it 'warns there is a PyPy update available' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     The PyPy project has released a security update! Please consider upgrading to pypy2.7-#{LATEST_PYPY_2_7}
          remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing pypy2.7-7.3.1
        OUTPUT
      end
    end
  end

  context 'with a runtime.txt containing pypy3.6-7.3.1' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pypy_3.6_outdated') }

    it 'warns there is a PyPy update available' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote:  !     The PyPy project has released a security update! Please consider upgrading to pypy3.6-#{LATEST_PYPY_3_6}
          remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing pypy3.6-7.3.1
        OUTPUT
      end
    end
  end
end
