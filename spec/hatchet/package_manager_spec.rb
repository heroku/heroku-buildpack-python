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
          remote:  !     Error: Couldn't find any supported Python package manager files.
          remote:  !     
          remote:  !     A Python app on Heroku must have either a 'requirements.txt' or
          remote:  !     'Pipfile' package manager file in the root directory of its
          remote:  !     source code.
          remote:  !     
          remote:  !     Currently the root directory of your app contains:
          remote:  !     
          remote:  !     runtime.txt
          remote:  !     subdir/
          remote:  !     
          remote:  !     If your app already has a package manager file, check that it:
          remote:  !     
          remote:  !     1. Is in the top level directory (not a subdirectory).
          remote:  !     2. Has the correct spelling (the filenames are case-sensitive).
          remote:  !     3. Isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     
          remote:  !     Otherwise, add a package manager file to your app. If your app has
          remote:  !     no dependencies, then create an empty 'requirements.txt' file.
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
