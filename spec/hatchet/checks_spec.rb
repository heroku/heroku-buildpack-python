# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Buildpack validation checks' do
  context 'when there are duplicate Python buildpacks set on the app' do
    let(:buildpacks) { %i[default default] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks:, allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: The Python buildpack has already been run this build.
          remote:  !     
          remote:  !     An existing Python installation was found in the build directory
          remote:  !     from a buildpack run earlier in the build.
          remote:  !     
          remote:  !     This normally means there are duplicate Python buildpacks set
          remote:  !     on your app, which isn't supported, can cause errors and
          remote:  !     slow down builds.
          remote:  !     
          remote:  !     Check the buildpacks set on your app and remove any duplicate
          remote:  !     Python buildpack entries:
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#remove-classic-buildpacks
          remote:  !     
          remote:  !     Note: This error replaces the deprecation warning which was
          remote:  !     displayed in build logs starting 13th December 2024.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when the app source contains a broken Python install' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_in_app_source', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Existing '.heroku/python/' directory found.
          remote:  !     
          remote:  !     Your app's source code contains an existing directory named
          remote:  !     '.heroku/python/', which is where the Python buildpack needs
          remote:  !     to install its files. This existing directory contains:
          remote:  !     
          remote:  !     .heroku/python/
          remote:  !     .heroku/python/bin
          remote:  !     .heroku/python/bin/python
          remote:  !     
          remote:  !     Writing to internal locations used by the Python buildpack
          remote:  !     isn't supported and can cause unexpected errors.
          remote:  !     
          remote:  !     If you have committed a '.heroku/python/' directory to your
          remote:  !     Git repo, you must delete it or use a different location.
          remote:  !     
          remote:  !     Otherwise, check that an earlier buildpack or 'bin/pre_compile'
          remote:  !     hook hasn't created this directory.
          remote:  !     
          remote:  !     Note: This error replaces the deprecation warning which was
          remote:  !     displayed in build logs starting 13th December 2024.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when the app source contains a venv directory' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/venv_in_app_source', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Existing '.venv/' directory found.
          remote:  !     
          remote:  !     Your app's source code contains an existing directory named
          remote:  !     '.venv/', which looks like a Python virtual environment:
          remote:  !     
          remote:  !     .venv/
          remote:  !     .venv/bin
          remote:  !     .venv/bin/python
          remote:  !     .venv/pyvenv.cfg
          remote:  !     
          remote:  !     Including a virtual environment directory in your app source
          remote:  !     isn't supported since the files within it are specific to a
          remote:  !     single machine and so won't work when run somewhere else.
          remote:  !     
          remote:  !     If you've committed a '.venv/' directory to your Git repo, you
          remote:  !     must delete it and add the directory to your .gitignore file.
          remote:  !     
          remote:  !     To do this:
          remote:  !     1. Run 'git rm --cached -r .venv/' to remove the directory
          remote:  !        from the Git index.
          remote:  !     2. Create a '.gitignore' file in the root of your repository
          remote:  !        if it doesn't already exist.
          remote:  !     3. Add the '.venv/' directory to the .gitignore file as a
          remote:  !        new entry on its own line (don't include the quotes).
          remote:  !     4. Commit these changes using 'git add --all' followed by
          remote:  !        'git commit'.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://docs.github.com/en/get-started/git-basics/ignoring-files
          remote:  !     
          remote:  !     If the directory was created by a 'bin/pre_compile' hook or
          remote:  !     an earlier buildpack, you must instead update them to create
          remote:  !     the virtual environment in a different location.
          remote:  !     
          remote:  !     Note: This error replaces the warning which was displayed in
          remote:  !     build logs starting 2nd September 2025.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end
end
