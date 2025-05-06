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
          remote:  !     by the more widely supported .python-version file:
          remote:  !     https://devcenter.heroku.com/changelog-items/3141
          remote:  !     
          remote:  !     Please switch to using a .python-version file instead.
          remote:  !     
          remote:  !     Delete your runtime.txt file and create a new file in the
          remote:  !     root directory of your app named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' character at the start of the
          remote:  !     filename. Don't add a file extension such as '.txt'.
          remote:  !     
          remote:  !     In the new file, specify your app's major Python version number
          remote:  !     only. Don't include quotes or a 'python-' prefix.
          remote:  !     
          remote:  !     For example, to request the latest version of Python 3.9,
          remote:  !     update your .python-version file so it contains exactly:
          remote:  !     3.9
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     In the future support for runtime.txt will be removed and
          remote:  !     this warning will be made an error.
          remote: 
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
          remote:  !     Warning: A Python patch update is available!
          remote:  !     
          remote:  !     Your app is using Python 3.9.0, however, there is a newer
          remote:  !     patch release of Python 3.9 available: #{LATEST_PYTHON_3_9}
          remote:  !     
          remote:  !     It is important to always use the latest patch version of
          remote:  !     Python to keep your app secure.
          remote:  !     
          remote:  !     Update your runtime.txt file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.9.0, and instead only specify
          remote:  !     the major Python version of 3.9 in your runtime.txt file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.9.0
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
          remote: 
          remote:  !     Warning: A Python patch update is available!
          remote:  !     
          remote:  !     Your app is using Python 3.10.0, however, there is a newer
          remote:  !     patch release of Python 3.10 available: #{LATEST_PYTHON_3_10}
          remote:  !     
          remote:  !     It is important to always use the latest patch version of
          remote:  !     Python to keep your app secure.
          remote:  !     
          remote:  !     Update your .python-version file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.10.0, and instead only specify
          remote:  !     the major Python version of 3.10 in your .python-version file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.10.0
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        OUTPUT
      end
    end
  end
end
