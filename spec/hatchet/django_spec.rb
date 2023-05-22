# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Django support' do
  describe 'collectstatic' do
    context 'when building a Django project' do
      let(:app) { Hatchet::Runner.new('python-getting-started') }

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
