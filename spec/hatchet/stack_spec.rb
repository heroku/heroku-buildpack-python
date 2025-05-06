# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Stack changes' do
  context 'when the stack is upgraded from Heroku-22 to Heroku-24', stacks: %w[heroku-22] do
    # This test performs an initial build using an older buildpack version, followed by a build
    # using the current version. This ensures that the current buildpack can successfully read
    # the stack metadata written to the build cache in the past. The buildpack version chosen is
    # the oldest to support Heroku-24, and which had an older default Python version so we can
    # also prove that clearing the cache didn't lose the sticky Python version metadata.
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#archive/v250'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks:) }

    it 'clears the cache before installing again whilst preserving the sticky Python version' do
      app.deploy do |app|
        expect(app.output).to include('Building on the Heroku-22 stack')
        app.update_stack('heroku-24')
        update_buildpacks(app, [:default])
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same major version as the last build: Python 3.12
          remote: 
          remote:  !     Warning: No Python version was specified.
          remote:  !     
          remote:  !     Your app doesn't specify a Python version and so the buildpack
          remote:  !     picked a default version for you.
          remote:  !     
          remote:  !     Relying on this default version isn't recommended, since it
          remote:  !     can change over time and may not be consistent with your local
          remote:  !     development environment, CI or other instances of your app.
          remote:  !     
          remote:  !     Please configure an explicit Python version for your app.
          remote:  !     
          remote:  !     Create a new file in the root directory of your app named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' character at the start of the
          remote:  !     filename. Don't add a file extension such as '.txt'.
          remote:  !     
          remote:  !     In the new file, specify your app's major Python version number
          remote:  !     only. Don't include quotes or a 'python-' prefix.
          remote:  !     
          remote:  !     For example, to request the latest version of Python 3.12,
          remote:  !     update your .python-version file so it contains exactly:
          remote:  !     3.12
          remote:  !     
          remote:  !     We strongly recommend that you don't specify the Python patch
          remote:  !     version number, since it will pin your app to an exact Python
          remote:  !     version and so stop your app from receiving security updates
          remote:  !     each time it builds.
          remote:  !     
          remote:  !     If your app already has a .python-version file, check that it:
          remote:  !     
          remote:  !     1. Is in the top level directory (not a subdirectory).
          remote:  !     2. Is named exactly '.python-version' in all lowercase.
          remote:  !     3. Isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     4. Has been added to the Git repository using 'git add --all'
          remote:  !        and then committed using 'git commit'.
          remote:  !     
          remote:  !     In the future we will require the use of a .python-version
          remote:  !     file and this warning will be made an error.
          remote: 
          remote: -----> Discarding cache since:
          remote:        - The stack has changed from heroku-22 to heroku-24
          remote:        - The Python version has changed from 3.12.3 to #{LATEST_PYTHON_3_12}
          remote:        - The pip version has changed
          remote: -----> Installing Python #{LATEST_PYTHON_3_12}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
    end
  end

  context 'when the stack is downgraded from Heroku-24 to Heroku-22', stacks: %w[heroku-24] do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.13') }

    it 'clears the cache before installing again' do
      app.deploy do |app|
        expect(app.output).to include('Building on the Heroku-24 stack')
        app.update_stack('heroku-22')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The stack has changed from heroku-24 to heroku-22
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
    end
  end
end
