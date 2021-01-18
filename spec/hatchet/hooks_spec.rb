# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Compile hooks' do
  context 'when an app has bin/pre_compile and bin/post_compile scripts' do
    let(:app) { new_app('spec/fixtures/hooks', config: { 'SOME_APP_CONFIG_VAR' => '1' }) }

    it 'runs the hooks with the correct environment' do
      expected_env_vars = %w[
        _
        BIN_DIR
        BPLOG_PREFIX
        BUILD_DIR
        BUILDPACK_LOG_FILE
        CACHE_DIR
        C_INCLUDE_PATH
        CPLUS_INCLUDE_PATH
        DYNO
        ENV_DIR
        EXPORT_PATH
        HOME
        LANG
        LD_LIBRARY_PATH
        LIBRARY_PATH
        OLDPWD
        PATH
        PIP_NO_PYTHON_VERSION_WARNING
        PKG_CONFIG_PATH
        PROFILE_PATH
        PWD
        PYTHONUNBUFFERED
        REQUEST_ID
        SHLVL
        SOME_APP_CONFIG_VAR
        SOURCE_VERSION
        STACK
      ]
      # On Heroku-16 'OLDPWD' will not be set, since for bash <4.4 it's not exported to subshells:
      # https://github.com/heroku/heroku-buildpack-python/pull/1011#issuecomment-665117835
      expected_env_vars.delete('OLDPWD') if app.stack == 'heroku-16'

      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Running pre-compile hook
          remote: pre_compile ran with env vars:
          remote: #{expected_env_vars.join("\nremote: ")}
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: .*
          remote: -----> Installing requirements with pip
          remote: -----> Running post-compile hook
          remote: post_compile ran with env vars:
          remote: #{expected_env_vars.join("\nremote: ")}
        REGEX
      end
    end
  end
end
