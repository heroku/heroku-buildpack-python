# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Compile hooks' do
  # TODO: Run this on Heroku-22 too, once it has also migrated to the new build infrastructure.
  # (Currently the test fails on the old infrastructure due to subtle differences in system PATH elements.)
  context 'when an app has bin/pre_compile and bin/post_compile scripts', stacks: %w[heroku-20 heroku-24] do
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks', config: { 'SOME_APP_CONFIG_VAR' => '1' }) }

    it 'runs the hooks with the correct environment' do
      app.deploy do |app|
        output = clean_output(app.output)

        expect(output).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Running pre-compile hook
          remote: ~ pre_compile ran with env vars:
          remote: BUILD_DIR=/tmp/build_<hash>
          remote: CACHE_DIR=/tmp/codon/tmp/cache
          remote: C_INCLUDE_PATH=/app/.heroku/python/include
          remote: CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote: ENV_DIR=/tmp/...
          remote: HOME=/app
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PIP_NO_PYTHON_VERSION_WARNING=1
          remote: PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote: PWD=/tmp/build_<hash>
          remote: PYTHONUNBUFFERED=1
          remote: SOME_APP_CONFIG_VAR=1
          remote: SOURCE_VERSION=...
          remote: STACK=#{app.stack}
          remote: ~ pre_compile complete
        OUTPUT

        expect(output).to include(<<~OUTPUT)
          remote: -----> Installing requirements with pip
          remote: -----> Running post-compile hook
          remote: ~ post_compile ran with env vars:
          remote: BUILD_DIR=/tmp/build_<hash>
          remote: CACHE_DIR=/tmp/codon/tmp/cache
          remote: C_INCLUDE_PATH=/app/.heroku/python/include
          remote: CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote: ENV_DIR=/tmp/...
          remote: HOME=/app
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PIP_NO_PYTHON_VERSION_WARNING=1
          remote: PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote: PWD=/tmp/build_<hash>
          remote: PYTHONUNBUFFERED=1
          remote: SOME_APP_CONFIG_VAR=1
          remote: SOURCE_VERSION=...
          remote: STACK=#{app.stack}
          remote: ~ post_compile complete
        OUTPUT
      end
    end
  end
end
