# frozen_string_literal: true

require_relative '../spec_helper'

# Tests that broken user-provided env vars don't take precedence over those set by this buildpack
# and break running Python. This is particularly important when using shared builds of Python,
# since they rely upon `LD_LIBRARY_PATH` being correct. This list of env vars is based on those
# that used to be set to different values by `bin/release` in very old versions of the buildpack:
# https://github.com/heroku/heroku-buildpack-python/blob/27abdfe7d7ad104dabceb45641415251e965671c/bin/release#L11-L18
BROKEN_CONFIG_VARS = {
  LD_LIBRARY_PATH: '/invalid-path',
  LIBRARY_PATH: '/invalid-path',
  PATH: '/invalid-path',
  PYTHONHOME: '/invalid-path',
  PYTHONPATH: '/invalid-path',
}.freeze

RSpec.describe 'Django support' do
  describe 'collectstatic' do
    context 'when building a Django project' do
      let(:app) { Hatchet::Runner.new('python-getting-started', config: BROKEN_CONFIG_VARS) }

      it 'runs collectstatic' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> \\$ python manage.py collectstatic --noinput
            remote:        WARNING:root:No DATABASE_URL environment variable set, and so no databases setup
            remote:        \\d+ static files? copied to '/tmp/build_.*/staticfiles', \\d+ post-processed.
          REGEX
        end
      end
    end

    context 'when Django is installed but manage.py does not exist' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_django_latest') }

      it 'skips collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('Skipping Django collectstatic since no manage.py file found.')
          expect(app.output).not_to include('manage.py collectstatic')
        end
      end
    end

    context 'when DISABLE_COLLECTSTATIC=1' do
      let(:app) do
        Hatchet::Runner.new('spec/fixtures/requirements_django_latest', config: { 'DISABLE_COLLECTSTATIC' => '1' })
      end

      it 'skips collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.')
          expect(app.output).not_to include('manage.py collectstatic')
        end
      end
    end

    context 'when DISABLE_COLLECTSTATIC=0' do
      let(:app) { Hatchet::Runner.new('python-getting-started', config: { 'DISABLE_COLLECTSTATIC' => '0' }) }

      it 'still runs collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('manage.py collectstatic')
        end
      end
    end

    context 'when DISABLE_COLLECTSTATIC is null' do
      let(:app) { Hatchet::Runner.new('python-getting-started', config: { 'DISABLE_COLLECTSTATIC' => '' }) }

      it 'still runs collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('manage.py collectstatic')
        end
      end
    end

    context 'when .heroku/collectstatic_disabled exists' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/django_collectstatic_disabled_file') }

      it 'skips collectstatic with a deprecation warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Skipping Django collectstatic since the file '.heroku/collectstatic_disabled' exists.
            remote:  !     This approach is deprecated, please set the env var DISABLE_COLLECTSTATIC=1 instead.
          OUTPUT
          expect(app.output).not_to include('manage.py collectstatic')
        end
      end
    end

    context 'when building a broken Django project' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/django_broken_project', allow_failure: true) }

      it 'fails collectstatic with an informative error message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
            remote: -----> \\$ python manage.py collectstatic --noinput
            remote:        Traceback \\(most recent call last\\):
            remote:        .*
            remote:        ModuleNotFoundError: No module named 'gettingstarted'
            remote: 
            remote:  !     Error while running '\\$ python manage.py collectstatic --noinput'.
          REGEX
        end
      end
    end
  end
end
