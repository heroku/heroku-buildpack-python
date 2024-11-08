# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Stack changes' do
  context 'when the stack is upgraded from Heroku-22 to Heroku-24', stacks: %w[heroku-22] do
    # This test performs an initial build using an older buildpack version, followed
    # by a build using the current version. This ensures that the current buildpack
    # can successfully read the stack metadata written to the build cache in the past.
    # The buildpack version chosen is one which had an older default Python version, so
    # we can also prove that clearing the cache didn't lose the Python version metadata.
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v250'] }
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
          remote: -----> No Python version was specified. Using the same version as the last build: Python 3.12.3
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Discarding cache since:
          remote:        - The stack has changed from heroku-22 to heroku-24
          remote:        - The pip version has changed
          remote: -----> Installing Python 3.12.3
          remote: 
          remote:  !     Warning: A Python security update is available!
          remote:  !     
          remote:  !     Upgrade as soon as possible to: Python #{LATEST_PYTHON_3_12}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote: 
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
    end
  end

  context 'when the stack is downgraded from Heroku-24 to Heroku-22', stacks: %w[heroku-24] do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified') }

    it 'clears the cache before installing again' do
      app.deploy do |app|
        expect(app.output).to include('Building on the Heroku-24 stack')
        app.update_stack('heroku-22')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Discarding cache since:
          remote:        - The stack has changed from heroku-24 to heroku-22
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
    end
  end
end
