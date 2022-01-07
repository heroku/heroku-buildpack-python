# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Django support' do
  describe 'Unsupported version warnings' do
    context 'when requirements.txt contains Django==1.11' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_django_1.11') }

      it 'warns about Django end of support' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Installing requirements with pip
            remote:  !     Your Django version is nearing the end of its community support.
            remote:  !     Upgrade to continue to receive security updates and for the best experience with Django.
            remote:  !     For more information, check out https://www.djangoproject.com/download/#supported-versions
          OUTPUT
        end
      end
    end

    context 'when requirements.txt contains Django==2.1' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_django_2.1') }

      it 'does not warn about Django end of support' do
        app.deploy do |app|
          expect(app.output).not_to include('https://www.djangoproject.com/download/#supported-versions')
        end
      end
    end
  end

  describe 'collectstatic' do
    context 'when building a Django project' do
      let(:app) { Hatchet::Runner.new('python-getting-started') }

      it 'runs collectstatic' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> \\$ python manage.py collectstatic --noinput
            remote:        \\d+ static files copied to '/tmp/build_.*/staticfiles', \\d+ post-processed.
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
          expect(app.output).not_to include('static files copied')
        end
      end
    end

    context 'when DISABLE_COLLECTSTATIC=0' do
      let(:app) { Hatchet::Runner.new('python-getting-started', config: { 'DISABLE_COLLECTSTATIC' => '0' }) }

      it 'still runs collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('static files copied')
        end
      end
    end

    context 'when DISABLE_COLLECTSTATIC is null' do
      let(:app) { Hatchet::Runner.new('python-getting-started', config: { 'DISABLE_COLLECTSTATIC' => '' }) }

      it 'still runs collectstatic' do
        app.deploy do |app|
          expect(app.output).to include('static files copied')
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
          expect(app.output).not_to include('static files copied')
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
