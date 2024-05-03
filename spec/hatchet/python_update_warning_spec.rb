# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'warns there is a Python update available' do |requested_version, latest_version|
  it 'warns there is a Python update available' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote:  !     
        remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{latest_version}
        remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
        remote:  !     
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
        remote: -----> Using Python version specified in runtime.txt
        remote:  !     
        remote:  !     Requested runtime 'python-#{requested_version}' is not available for this stack (#{app.stack}).
        remote:  !     
        remote:  !     For a list of the supported Python versions, see:
        remote:  !     https://devcenter.heroku.com/articles/python-support#supported-runtimes
        remote:  !     
      OUTPUT
    end
  end
end

RSpec.describe 'Python update warnings' do
  context 'with a runtime.txt containing python-3.8.12' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8_outdated', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'warns about both the deprecated major version and the patch update' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in runtime.txt
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
            remote:  !     
            remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{LATEST_PYTHON_3_8}
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing python-3.8.12
          REGEX
        end
      end
    end

    context 'when using Heroku-22 or newer', stacks: %w[heroku-22 heroku-24] do
      let(:allow_failure) { true }

      # We only support Python 3.8 on Heroku-20 and older.
      include_examples 'aborts the build without showing an update warning', '3.8.12'
    end
  end

  context 'with a runtime.txt containing python-3.9.12' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9_outdated', allow_failure:) }

    context 'when using Heroku-22 or older', stacks: %w[heroku-20 heroku-22] do
      include_examples 'warns there is a Python update available', '3.9.12', LATEST_PYTHON_3_9
    end

    context 'when using Heroku-24', stacks: %w[heroku-24] do
      let(:allow_failure) { true }

      # We only support Python 3.9 on Heroku-22 and older.
      include_examples 'aborts the build without showing an update warning', '3.9.12'
    end
  end

  context 'with a runtime.txt containing python-3.10.5' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10_outdated', allow_failure:) }

    include_examples 'warns there is a Python update available', '3.10.5', LATEST_PYTHON_3_10
  end

  context 'with a runtime.txt containing python-3.11.0' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.11_outdated', allow_failure:) }

    include_examples 'warns there is a Python update available', '3.11.0', LATEST_PYTHON_3_11
  end

  context 'with a runtime.txt containing python-3.12.0' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.12_outdated', allow_failure:) }

    include_examples 'warns there is a Python update available', '3.12.0', LATEST_PYTHON_3_12
  end
end
