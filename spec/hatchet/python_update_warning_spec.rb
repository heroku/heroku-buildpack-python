# frozen_string_literal: true

require_relative '../spec_helper'

# NOTE: We use the oldest patch releases (ie the '.0' releases) since we also want to test against
# the oldest Python versions available to users. This is particularly important given that older
# patch releases will bundle older pip, and the buildpack uses that pip during bootstrapping.
RSpec.describe 'Python update warnings' do
  context 'with a runtime.txt containing an outdated patch version that is also a deprecated major version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_outdated_and_deprecated') }

    it 'warns about both the deprecated major version and the patch update' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9.0 specified in runtime.txt
          remote: 
          remote:  !     Warning: The runtime.txt file is deprecated.
          remote:  !     
          remote:  !     The runtime.txt file is deprecated since it has been replaced
          remote:  !     by the more widely supported .python-version file.
          remote:  !     
          remote:  !     Please delete your runtime.txt file and create a new file named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' at the start of the filename.
          remote:  !     
          remote:  !     In the new file, specify your app's Python version without
          remote:  !     quotes or a 'python-' prefix. For example:
          remote:  !     3.9
          remote:  !     
          remote:  !     We strongly recommend that you use the major version form
          remote:  !     instead of pinning to an exact version, since it will allow
          remote:  !     your app to receive Python security updates.
          remote:  !     
          remote:  !     In the future support for runtime.txt will be removed and
          remote:  !     this warning will be made an error.
          remote: 
          remote: -----> Installing Python 3.9.0
          remote: 
          remote:  !     Warning: Support for Python 3.9 is ending soon!
          remote:  !     
          remote:  !     Python 3.9 will reach its upstream end-of-life in October 2025,
          remote:  !     at which point it will no longer receive security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, support for Python 3.9 will be removed from this
          remote:  !     buildpack on 7th January 2026.
          remote:  !     
          remote:  !     Upgrade to a newer Python version as soon as possible, by
          remote:  !     changing the version in your runtime.txt file.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote: 
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

  context 'with a .python-version file containing an outdated patch version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_outdated') }

    it 'warns there is a Python update available' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.10.0 specified in .python-version
          remote: -----> Installing Python 3.10.0
          remote: 
          remote:  !     Warning: A Python security update is available!
          remote:  !     
          remote:  !     Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_10}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote: 
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        OUTPUT
      end
    end
  end
end
