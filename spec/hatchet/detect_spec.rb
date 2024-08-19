# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Buildpack detection' do
  # This spec only tests cases where detection fails, since the success cases
  # are already tested in the specs for general buildpack functionality.

  context 'when there are no recognised Python project files' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/no_python_project_files', allow_failure: true) }

    it 'fails detection' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> App not compatible with buildpack: #{DEFAULT_BUILDPACK_URL}
          remote:        
          remote:  !     Error: Your app is configured to use the Python buildpack,
          remote:  !     but we couldn't find any supported Python project files.
          remote:  !     
          remote:  !     A Python app on Heroku must have either a 'requirements.txt' or
          remote:  !     'Pipfile' package manager file in the root directory of its
          remote:  !     source code.
          remote:  !     
          remote:  !     Currently the root directory of your app contains:
          remote:  !     
          remote:  !     README.md
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
          remote: 
          remote:        More info: https://devcenter.heroku.com/articles/buildpacks#detection-failure
        OUTPUT
      end
    end
  end
end
