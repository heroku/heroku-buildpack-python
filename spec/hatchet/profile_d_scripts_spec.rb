# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe '.profile.d/ scripts' do
  it 'sets the required run-time env vars' do
    Hatchet::Runner.new('spec/fixtures/procfile', run_multi: true).deploy do |app|
      # These are written as a single test to reduce end to end test time. (This repo uses parallel_split_test,
      # so we can't perform app setup in a `before(:all)` and have multiple tests run against the single app.)
      # These tests supplement the run-time env var tests performed for each package manager, so intentionally
      # don't duplicate those.

      # Check user-provided env var values are preserved/overridden as appropriate.
      # Also checks that the WEB_CONCURRENCY related log output is not shown for worker dynos.
      list_envs_cmd = 'printenv | sort | grep -vE "^(_|DYNO|HOME|PORT|PS1|PWD|SHLVL|TERM)="'
      user_env_vars = [
        'DYNO_RAM=this-should-be-overridden',
        'FORWARDED_ALLOW_IPS=this-should-be-overridden',
        'GUNICORN_CMD_ARGS=this-should-be-preserved',
        'LANG=this-should-be-overridden',
        'LD_LIBRARY_PATH=/this-should-be-preserved',
        'LIBRARY_PATH=/this-should-be-preserved',
        'PATH=/this-should-be-preserved:/usr/local/bin:/usr/bin:/bin',
        'PYTHONHOME=/this-should-be-overridden',
        'PYTHONPATH=/this-should-be-preserved',
        'PYTHONUNBUFFERED=this-should-be-overridden',
        'WEB_CONCURRENCY=this-should-be-preserved',
      ]
      app.run_multi(list_envs_cmd, heroku: { env: user_env_vars.join(';'), type: 'example-worker' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          DYNO_RAM=512
          FORWARDED_ALLOW_IPS=*
          GUNICORN_CMD_ARGS=this-should-be-preserved
          LANG=C.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib:/this-should-be-preserved
          LIBRARY_PATH=/app/.heroku/python/lib:/this-should-be-preserved
          PATH=/app/.heroku/python/bin:/this-should-be-preserved:/usr/local/bin:/usr/bin:/bin
          PIP_DISABLE_PIP_VERSION_CHECK=1
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/this-should-be-preserved
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=this-should-be-preserved
        OUTPUT
      end

      list_concurrency_envs_cmd = 'printenv | sort | grep -E "^(DYNO_RAM|WEB_CONCURRENCY)="'

      # Check WEB_CONCURRENCY support when using a Standard-1X dyno.
      # We set the process type to `web` so that we can test the web-dyno-only log output.
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'standard-1x', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 512 MB available memory and 8 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 2 based on the available memory.
          DYNO_RAM=512
          WEB_CONCURRENCY=2
        OUTPUT
      end

      # Standard-2X
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'standard-2x', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 1024 MB available memory and 8 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 4 based on the available memory.
          DYNO_RAM=1024
          WEB_CONCURRENCY=4
        OUTPUT
      end

      # Performance-M
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'performance-m', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 2560 MB available memory and 2 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 5 based on the number of CPU cores.
          DYNO_RAM=2560
          WEB_CONCURRENCY=5
        OUTPUT
      end

      # Performance-L
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'performance-l', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 14336 MB available memory and 8 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 17 based on the number of CPU cores.
          DYNO_RAM=14336
          WEB_CONCURRENCY=17
        OUTPUT
      end

      # Performance-L-RAM
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'performance-l-ram', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 30720 MB available memory and 4 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 9 based on the number of CPU cores.
          DYNO_RAM=30720
          WEB_CONCURRENCY=9
        OUTPUT
      end

      # Performance-XL
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'performance-xl', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 63488 MB available memory and 8 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 17 based on the number of CPU cores.
          DYNO_RAM=63488
          WEB_CONCURRENCY=17
        OUTPUT
      end

      # Performance-2XL
      app.run_multi(list_concurrency_envs_cmd, heroku: { size: 'performance-2xl', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 129024 MB available memory and 16 CPU cores.
          Python buildpack: Defaulting WEB_CONCURRENCY to 33 based on the number of CPU cores.
          DYNO_RAM=129024
          WEB_CONCURRENCY=33
        OUTPUT
      end

      # Check that WEB_CONCURRENCY is preserved if set, but that we still set DYNO_RAM.
      app.run_multi(list_concurrency_envs_cmd, heroku: { env: 'WEB_CONCURRENCY=999', type: 'web' }) do |output, _|
        expect(output).to eq(<<~OUTPUT)
          Python buildpack: Detected 512 MB available memory and 8 CPU cores.
          Python buildpack: Skipping automatic configuration of WEB_CONCURRENCY since it's already set.
          DYNO_RAM=512
          WEB_CONCURRENCY=999
        OUTPUT
      end
    end
  end
end
