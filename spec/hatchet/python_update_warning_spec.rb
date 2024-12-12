# frozen_string_literal: true

require_relative '../spec_helper'

# NOTE: We use the oldest patch releases (ie the '.0' releases) since we also want to test against
# the oldest Python versions available to users. This is particularly important given that older
# patch releases will bundle older pip, and the buildpack uses that pip during bootstrapping.
RSpec.describe 'Python update warnings' do
  context 'with a runtime.txt containing an outdated patch version that is also a deprecated major version' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_outdated_and_deprecated', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'warns about both the deprecated major version and the patch update' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python 3.8.0 specified in runtime.txt
            remote: -----> Installing Python 3.8.0
            remote: 
            remote:  !     Warning: Support for Python 3.8 is ending soon!
            remote:  !     
            remote:  !     Python 3.8 reached its upstream end-of-life on 7th October 2024, and so
            remote:  !     no longer receives security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Support for Python 3.8 will be removed from this buildpack on 7th January 2025.
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote: 
            remote: 
            remote:  !     Warning: A Python security update is available!
            remote:  !     
            remote:  !     Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_8}
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote: 
            remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22 or newer', stacks: %w[heroku-22 heroku-24] do
      let(:allow_failure) { true }

      # We only support Python 3.8 on Heroku-20 and older.
      it 'aborts the build without showing an update warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> Using Python 3.8.0 specified in runtime.txt
            remote: 
            remote:  !     Error: Python 3.8.0 isn't available for this stack (#{app.stack}).
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

  context 'with a .python-version file containing an outdated patch version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_outdated') }

    it 'warns there is a Python update available' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in .python-version
          remote: -----> Installing Python 3.9.0
          remote: 
          remote:  !     Warning: A Python security update is available!
          remote:  !     
          remote:  !     Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_9}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote: 
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        OUTPUT
      end
    end
  end
end
