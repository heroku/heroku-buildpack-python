# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Buildpack validation checks' do
  context 'when the app source contains a broken Python install' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_in_app_source', allow_failure: true) }

    it 'fails detection' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: 
          remote:  !     Internal Error: Unable to locate the bundled copy of pip.
          remote:  !     
          remote:  !     The Python buildpack could not locate the copy of pip bundled
          remote:  !     inside Python's 'ensurepip' module:
          remote:  !     
          remote:  !     find: ‘/app/.heroku/python/lib/python3.13/ensurepip/_bundled/’: No such file or directory
          remote:  !     /app/.heroku/python/
          remote:  !     /app/.heroku/python/bin
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end
end
