# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Compile hooks' do
  # This spec skips testing the passing post_compile hook case, since that's already tested
  # via the package manager and CI tests.

  # Tests two of the four hooks result permutations in the same test to reduce end to end time.
  context 'when an app has a passing bin/pre_compile and a failing bin/post_compile script' do
    let(:config) { { SOME_APP_CONFIG_VAR: '1' } }
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks_pre_compile_pass_post_compile_fail', config:, allow_failure: true) }

    it 'runs the pre_compile hook but aborts the build during the post_compile hook with a suitable error message' do
      app.deploy do |app|
        output = clean_output(app.output)

        expect(output).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Running bin/pre_compile hook
          remote:        ~ pre_compile ran with env vars:
          remote:        BUILD_DIR=/tmp/build_.+
          remote:        CACHE_DIR=/tmp/codon/tmp/cache
          remote:        C_INCLUDE_PATH=/app/.heroku/python/include
          remote:        CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote:        ENV_DIR=/tmp/.+
          remote:        LANG=en_US.UTF-8
          remote:        LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote:        LIBRARY_PATH=/app/.heroku/python/lib
          remote:        PATH=/app/.heroku/python/bin::/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote:        PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote:        PYTHONUNBUFFERED=1
          remote:        SOME_APP_CONFIG_VAR=1
          remote:        ~ pre_compile complete
        REGEX

        expect(output).to include(<<~OUTPUT)
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

  context 'when an app has a failing bin/pre_compile script' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/hooks_pre_compile_fail', allow_failure: true) }

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
end
