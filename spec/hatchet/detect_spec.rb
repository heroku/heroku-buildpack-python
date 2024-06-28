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
          remote:  !     Error: Unable to find any Python project files.
          remote:  !     
          remote:  !     The Python buildpack is set on this app, however, no recognised
          remote:  !     Python related files were found.
          remote:  !     
          remote:  !     A Python app on Heroku must have either a 'requirements.txt' or
          remote:  !     'Pipfile' file in the root directory of its source code, so the
          remote:  !     buildpack knows which dependencies to install.
          remote:  !     
          remote:  !     Currently the root directory of your app contains:
          remote:  !     
          remote:  !     README.md
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
          remote:  !     If you are trying to deploy an app written in another language,
          remote:  !     you need to change the list of buildpacks set on your app.
          remote: 
          remote:        More info: https://devcenter.heroku.com/articles/buildpacks#detection-failure
        OUTPUT
      end
    end
  end
end
