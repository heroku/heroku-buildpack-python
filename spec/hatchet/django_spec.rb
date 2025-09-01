# frozen_string_literal: true

require_relative '../spec_helper'

# Tests that broken user-provided env vars don't take precedence over those set by this buildpack
# and break running Python. This is particularly important when using shared builds of Python,
# since they rely upon `LD_LIBRARY_PATH` being correct. Some of these are based on the env vars
# that used to be set by `bin/release` by very old versions of the buildpack:
# https://github.com/heroku/heroku-buildpack-python/blob/27abdfe7d7ad104dabceb45641415251e965671c/bin/release#L11-L18
BROKEN_CONFIG_VARS = {
  BUILD_DIR: '/invalid-path',
  C_INCLUDE_PATH: '/invalid-path',
  CACHE_DIR: '/invalid-path',
  CPLUS_INCLUDE_PATH: '/invalid-path',
  ENV_DIR: '/invalid-path',
  LD_LIBRARY_PATH: '/invalid-path',
  LIBRARY_PATH: '/invalid-path',
  PATH: '/invalid-path',
  PKG_CONFIG_PATH: '/invalid-path',
  PYTHONHOME: '/invalid-path',
  PYTHONPATH: '/invalid-path',
}.freeze

RSpec.describe 'Django support' do
  context 'when building latest Django with the app nested inside a subfolder' do
    # Also tests that app config vars are passed to the 'manage.py' script invocations.
    let(:config) { { EXPECTED_ENV_VAR: '1' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_staticfiles_latest_django', config:) }

    it 'runs collectstatic' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> \\$ python backend/manage.py collectstatic --noinput
          remote:        \\{'BUILDPACK_LOG_FILE': '/dev/null',
          remote:         'BUILD_DIR': '/tmp/build_\\w+',
          remote:         'CACHE_DIR': '/tmp/codon/tmp/cache',
          remote:         'CPLUS_INCLUDE_PATH': '/app/.heroku/python/include',
          remote:         'C_INCLUDE_PATH': '/app/.heroku/python/include',
          remote:         'DJANGO_SETTINGS_MODULE': 'testproject.settings',
          remote:         'ENV_DIR': '/tmp/.+',
          remote:         'EXPECTED_ENV_VAR': '1',
          remote:         'HOME': '/app',
          remote:         'LANG': 'en_US.UTF-8',
          remote:         'LD_LIBRARY_PATH': '/app/.heroku/python/lib',
          remote:         'LIBRARY_PATH': '/app/.heroku/python/lib',
          remote:         'PATH': '/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          remote:         'PKG_CONFIG_PATH': '/app/.heroku/python/lib/pkg-config',
          remote:         'PWD': '/tmp/build_\\w+',
          remote:         'PYTHONPATH': '\\.',
          remote:         'PYTHONUNBUFFERED': '1',
          remote:         'SOURCE_VERSION': '.+',
          remote:         'STACK': '#{app.stack}'\\}
          remote:        \\['/tmp/build_\\w+/backend',
          remote:         '/tmp/build_\\w+',
          remote:         '/app/.heroku/python/lib/python313.zip',
          remote:         '/app/.heroku/python/lib/python3.13',
          remote:         '/app/.heroku/python/lib/python3.13/lib-dynload',
          remote:         '/app/.heroku/python/lib/python3.13/site-packages'\\]
          remote:        1 static file copied to '/tmp/build_\\w+/backend/staticfiles'.
          remote: 
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  context 'when building legacy Django with broken env vars set' do
    # Also tests that app config vars are passed to the 'manage.py' script invocations.
    let(:config) { BROKEN_CONFIG_VARS.merge(EXPECTED_ENV_VAR: '1') }
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_staticfiles_legacy_django', config:) }

    it 'runs collectstatic' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> \\$ python manage.py collectstatic --noinput
          remote:        \\{'BUILDPACK_LOG_FILE': '/dev/null',
          remote:         'BUILD_DIR': '/invalid-path',
          remote:         'CACHE_DIR': '/invalid-path',
          remote:         'CPLUS_INCLUDE_PATH': '/invalid-path',
          remote:         'C_INCLUDE_PATH': '/invalid-path',
          remote:         'DJANGO_SETTINGS_MODULE': 'testproject.settings',
          remote:         'ENV_DIR': '/invalid-path',
          remote:         'EXPECTED_ENV_VAR': '1',
          remote:         'HOME': '/app',
          remote:         'LANG': 'en_US.UTF-8',
          remote:         'LD_LIBRARY_PATH': '/app/.heroku/python/lib',
          remote:         'LIBRARY_PATH': '/app/.heroku/python/lib',
          remote:         'PATH': '/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          remote:         'PKG_CONFIG_PATH': '/invalid-path',
          remote:         'PWD': '/tmp/build_\\w+',
          remote:         'PYTHONPATH': '/invalid-path',
          remote:         'PYTHONUNBUFFERED': '1',
          remote:         'SOURCE_VERSION': '.+',
          remote:         'STACK': '#{app.stack}'\\}
          remote:        \\['/tmp/build_\\w+',
          remote:         '/invalid-path',
          remote:         '/app/.heroku/python/lib/python39.zip',
          remote:         '/app/.heroku/python/lib/python3.9',
          remote:         '/app/.heroku/python/lib/python3.9/lib-dynload',
          remote:         '/app/.heroku/python/lib/python3.9/site-packages'\\]
          remote:        1 static file copied to '/tmp/build_\\w+/staticfiles'.
          remote: 
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  context 'when Django is installed but manage.py does not exist' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_no_manage_py') }

    it 'skips collectstatic' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> Skipping Django collectstatic since no manage.py file found.
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  context 'when DISABLE_COLLECTSTATIC=1' do
    let(:config) { { DISABLE_COLLECTSTATIC: '1' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_invalid_settings_module', config:) }

    it 'skips collectstatic' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> Skipping Django collectstatic since the env var DISABLE_COLLECTSTATIC is set.
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  context 'when .heroku/collectstatic_disabled exists' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_collectstatic_disabled_file') }

    it 'skips collectstatic with a deprecation warning' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> Skipping Django collectstatic since the file '.heroku/collectstatic_disabled' exists.
          remote: 
          remote:  !     Warning: The .heroku/collectstatic_disabled file is deprecated.
          remote:  !     
          remote:  !     Please remove the file and set the env var DISABLE_COLLECTSTATIC=1 instead.
          remote: 
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  # TODO: Backport the Python CNB implementation that allows skipping collectstatic automatically for this case.
  context 'when Django and manage.py exist but the Django staticfiles app is not enabled' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_staticfiles_app_not_enabled', allow_failure: true) }

    it 'fails collectstatic' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote:        Successfully installed Django-.+
          remote: -----> \\$ python manage.py collectstatic --noinput
          remote:        Unknown command: 'collectstatic'
          remote:        Type 'manage.py help' for usage.
          remote: 
          remote: 
          remote:  !     Error: Unable to generate Django static files.
          remote:  !     
          remote:  !     The 'python manage.py collectstatic --noinput' Django
          remote:  !     management command to generate static files failed.
          remote:  !     
          remote:  !     See the traceback above for details.
          remote:  !     
          remote:  !     You may need to update application code to resolve this error.
          remote:  !     Or, you can disable collectstatic for this application:
          remote:  !     
          remote:  !        \\$ heroku config:set DISABLE_COLLECTSTATIC=1
          remote:  !     
          remote:  !     https://devcenter.heroku.com/articles/django-assets
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  # For now this case produces the same error message as the one below, but once we backport the
  # Python CNB implementation that will change, so we want a dedicated test for this case.
  context 'when manage.py is configured with an invalid settings module' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_invalid_settings_module', allow_failure: true) }

    it 'fails collectstatic with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> \\$ python manage.py collectstatic --noinput
          remote:        Traceback \\(most recent call last\\):
          remote:        .+
          remote:        ModuleNotFoundError: No module named 'nonexistent-module'
          remote: 
          remote: 
          remote:  !     Error: Unable to generate Django static files.
          remote:  !     
          remote:  !     The 'python manage.py collectstatic --noinput' Django
          remote:  !     management command to generate static files failed.
          remote:  !     
          remote:  !     See the traceback above for details.
          remote:  !     
          remote:  !     You may need to update application code to resolve this error.
          remote:  !     Or, you can disable collectstatic for this application:
          remote:  !     
          remote:  !        \\$ heroku config:set DISABLE_COLLECTSTATIC=1
          remote:  !     
          remote:  !     https://devcenter.heroku.com/articles/django-assets
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  context 'when the staticfiles app is misconfigured and DEBUG_COLLECTSTATIC=1' do
    let(:config) { { DEBUG_COLLECTSTATIC: '1' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/django_staticfiles_misconfigured', config:, allow_failure: true) }

    # TODO: Sort the displayed env vars to make the order deterministic and then we can test more of the output.
    it 'fails collectstatic with an informative error message and prints env vars' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> \\$ python manage.py collectstatic --noinput
          remote:        Traceback \\(most recent call last\\):
          remote:        .+
          remote:        django.core.exceptions.ImproperlyConfigured: You're using the staticfiles app without having set the required STATIC_URL setting.
          remote: 
          remote: 
          remote:  !     Error: Unable to generate Django static files.
          remote:  !     
          remote:  !     The 'python manage.py collectstatic --noinput' Django
          remote:  !     management command to generate static files failed.
          remote:  !     
          remote:  !     See the traceback above for details.
          remote:  !     
          remote:  !     You may need to update application code to resolve this error.
          remote:  !     Or, you can disable collectstatic for this application:
          remote:  !     
          remote:  !        \\$ heroku config:set DISABLE_COLLECTSTATIC=1
          remote:  !     
          remote:  !     https://devcenter.heroku.com/articles/django-assets
          remote: 
          remote: 
          remote: \\*\\*\\*\\*\\*\\* Collectstatic environment variables:
          remote: 
          remote:        .+
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end
end
