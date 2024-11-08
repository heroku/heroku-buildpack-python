# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Compile hooks' do
  context 'when an app has bin/pre_compile and bin/post_compile scripts' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks', config: { 'SOME_APP_CONFIG_VAR' => '1' }) }

    it 'runs the hooks with the correct environment' do
      app.deploy do |app|
        output = clean_output(app.output)

        expect(output).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Running bin/pre_compile hook
          remote:        ~ pre_compile ran with env vars:
          remote:        BUILD_DIR=/tmp/build_<hash>
          remote:        CACHE_DIR=/tmp/codon/tmp/cache
          remote:        C_INCLUDE_PATH=/app/.heroku/python/include
          remote:        CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote:        ENV_DIR=/tmp/...
          remote:        HOME=/app
          remote:        LANG=en_US.UTF-8
          remote:        LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote:        LIBRARY_PATH=/app/.heroku/python/lib
          remote:        PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote:        PIP_NO_PYTHON_VERSION_WARNING=1
          remote:        PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote:        PWD=/tmp/build_<hash>
          remote:        PYTHONUNBUFFERED=1
          remote:        SOME_APP_CONFIG_VAR=1
          remote:        SOURCE_VERSION=...
          remote:        STACK=#{app.stack}
          remote:        ~ pre_compile complete
        OUTPUT

        expect(output).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote: -----> Running bin/post_compile hook
          remote:        ~ post_compile ran with env vars:
          remote:        BUILD_DIR=/tmp/build_<hash>
          remote:        CACHE_DIR=/tmp/codon/tmp/cache
          remote:        C_INCLUDE_PATH=/app/.heroku/python/include
          remote:        CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote:        ENV_DIR=/tmp/...
          remote:        HOME=/app
          remote:        LANG=en_US.UTF-8
          remote:        LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote:        LIBRARY_PATH=/app/.heroku/python/lib
          remote:        PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote:        PIP_NO_PYTHON_VERSION_WARNING=1
          remote:        PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote:        PWD=/tmp/build_<hash>
          remote:        PYTHONUNBUFFERED=1
          remote:        SOME_APP_CONFIG_VAR=1
          remote:        SOURCE_VERSION=...
          remote:        STACK=#{app.stack}
          remote:        ~ post_compile complete
        OUTPUT
      end
    end
  end

  context 'when an app has a failing bin/pre_compile script' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks_failing_pre_compile', allow_failure: true) }

    it 'aborts the build with a suitable error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Running bin/pre_compile hook
          remote:        Some pre_compile error!
          remote: 
          remote:  !     Error: Failed to run the bin/pre_compile script.
          remote:  !     
          remote:  !     We found a 'bin/pre_compile' script in your app source, so ran
          remote:  !     it to allow for customisation of the build process.
          remote:  !     
          remote:  !     However, this script exited with a non-zero exit status.
          remote:  !     
          remote:  !     Fix any errors output by your script above, or remove/rename
          remote:  !     the script to prevent it from being run during the build.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when an app has a failing bin/post_compile script' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks_failing_post_compile', allow_failure: true) }

    it 'aborts the build with a suitable error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Running bin/post_compile hook
          remote:        Some post_compile error!
          remote: 
          remote:  !     Error: Failed to run the bin/post_compile script.
          remote:  !     
          remote:  !     We found a 'bin/post_compile' script in your app source, so ran
          remote:  !     it to allow for customisation of the build process.
          remote:  !     
          remote:  !     However, this script exited with a non-zero exit status.
          remote:  !     
          remote:  !     Fix any errors output by your script above, or remove/rename
          remote:  !     the script to prevent it from being run during the build.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end
end
