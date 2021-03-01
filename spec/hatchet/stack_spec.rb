# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Stack changes' do
  context 'when the stack is upgraded from Heroku-18 to Heroku-20', stacks: %w[heroku-18] do
    # This test performs an initial build using an older buildpack version, followed
    # by a build using the current version. This ensures that the current buildpack
    # can successfully read the stack metadata written to the build cache in the past.
    # The buildpack version chosen is one which had an older default Python version, so
    # we can also prove that clearing the cache didn't lose the Python version metadata.
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v189'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks: buildpacks) }

    it 'clears the cache before installing again whilst preserving the sticky Python version' do
      app.deploy do |app|
        expect(app.output).to include('Building on the Heroku-18 stack')
        app.update_stack('heroku-20')
        update_buildpacks(app, [:default])
        app.commit!
        app.push!
        # TODO: The build log should explain that sticky-versioning has occurred,
        # so that users know why their app is on an older Python version.
        # TODO: The requirements output shouldn't say "installing from cache", since it's not.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote:  !     Python has released a security update! Please consider upgrading to python-#{LATEST_PYTHON_3_6}
          remote:        Learn More: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Stack has changed from heroku-18 to heroku-20, clearing cache
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing python-3.6.12
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
      end
    end
  end

  context 'when the stack is downgraded from Heroku-20 to Heroku-18', stacks: %w[heroku-20] do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified') }

    it 'clears the cache before installing again' do
      app.deploy do |app|
        expect(app.output).to include('Building on the Heroku-20 stack')
        app.update_stack('heroku-18')
        app.commit!
        app.push!
        # TODO: Stop using Python scripts before Python is installed (or else ensure system
        # Python is always used) to avoid the glibc errors below.
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: python: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.29' not found (required by python)
          remote: python: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.28' not found (required by python)
          remote: -----> Stack has changed from heroku-20 to heroku-18, clearing cache
          remote: -----> No change in requirements detected, installing from cache
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip 20.1.1, setuptools 47.1.1 and wheel 0.34.2
          remote: -----> Installing SQLite3
          remote: -----> Installing requirements with pip
          remote:        Collecting urllib3
        OUTPUT
      end
    end
  end
end
