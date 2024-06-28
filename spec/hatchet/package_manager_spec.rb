# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Package manager support' do
  context 'when there are no supported package manager files' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_only', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote:  !     
          remote:  !     Error: No supported Python package manager files were found.
          remote:  !     
          remote:  !     A Python app on Heroku must have either a 'requirements.txt' or
          remote:  !     'Pipfile' file in the root directory of its source code, so the
          remote:  !     buildpack knows which dependencies to install.
          remote:  !     
          remote:  !     Currently the root directory of your app contains:
          remote:  !     
          remote:  !     runtime.txt
          remote:  !     subdir/
          remote:  !     
          remote:  !     If you believe your app already has a 'requirements.txt' or
          remote:  !     'Pipfile' file, check that:
          remote:  !     
          remote:  !     1. The file is in the top level directory (not a subdirectory).
          remote:  !     2. The filename has the correct spelling and capitalisation.
          remote:  !     3. The filename isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     
          remote:  !     Otherwise, please create a 'requirements.txt' file in the root
          remote:  !     of your app source, which lists your app's Python dependencies
          remote:  !     (the file can be empty if your app has no dependencies).
          remote:  !     
          remote:  !     For help with using Python on Heroku, see:
          remote:  !     https://devcenter.heroku.com/articles/getting-started-with-python
          remote:  !     https://devcenter.heroku.com/articles/python-support
          remote:  !     
        OUTPUT
      end
    end
  end
end
