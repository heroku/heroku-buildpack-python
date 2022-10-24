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

RSpec.shared_examples 'warns about both EOL major version and the patch update' do |requested_version, latest_version|
  it 'warns there is a Python update available' do
    app.deploy do |app|
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote:  !     
        remote:  !     Python .* reached upstream end-of-life on .*, and is
        remote:  !     therefore no longer receiving security updates:
        remote:  !     https://devguide.python.org/versions/#supported-versions
        remote:  !     
        remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
        remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
        remote:  !     
        remote:  !     
        remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{latest_version}
        remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
        remote:  !     
        remote: -----> Installing python-#{requested_version}
      REGEX
    end
  end
end

RSpec.shared_examples 'aborts the build without showing an update warning' do |requested_version|
  it 'aborts the build without showing an update warning' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in runtime.txt
        remote:  !     Requested runtime 'python-#{requested_version}' is not available for this stack (#{app.stack}).
        remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Python update warnings' do
  context 'with a runtime.txt containing python-3.6.14' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.6_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'warns about both EOL major version and the patch update', '3.6.14', LATEST_PYTHON_3_6
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '3.6.14'
    end
  end

  context 'with a runtime.txt containing python-3.7.12' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.7_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'warns there is a Python update available', '3.7.12', LATEST_PYTHON_3_7
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '3.7.12'
    end
  end

  context 'with a runtime.txt containing python-3.8.12' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.8_outdated', allow_failure: allow_failure) }

    context 'when using Heroku-18 or Heroku-20', stacks: %w[heroku-18 heroku-20] do
      include_examples 'warns there is a Python update available', '3.8.12', LATEST_PYTHON_3_8
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      include_examples 'aborts the build without showing an update warning', '3.8.12'
    end
  end

  context 'with a runtime.txt containing python-3.9.12' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9_outdated') }

    include_examples 'warns there is a Python update available', '3.9.12', LATEST_PYTHON_3_9
  end

  context 'with a runtime.txt containing python-3.10.5' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10_outdated', allow_failure: allow_failure) }

    include_examples 'warns there is a Python update available', '3.10.5', LATEST_PYTHON_3_10
  end

  # TODO: Add a test for Python 3.11.0 once 3.11.1 is released.
end
