# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Buildpack validation checks' do
  context 'when there are duplicate Python buildpacks set on the app' do
    let(:buildpacks) { %i[default default] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks:, allow_failure: true) }

    it 'fails detection' do
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

    it 'fails detection' do
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
end
