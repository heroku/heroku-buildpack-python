# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Python' do
  describe 'cache' do
    it 'functions correctly' do
      new_app('python_default').deploy do |app|
        expect(app.output).to match(/Installing pip/)

        expect(app.output).not_to match('Requirements file has been changed, clearing cached dependencies')
        expect(app.output).not_to match('No change in requirements detected, installing from cache')
        expect(app.output).not_to match('No such file or directory')
        expect(app.output).not_to match('cp: cannot create regular file')

        # Redeploy with changed requirements file
        run!(%(echo "" >> requirements.txt))
        run!(%(echo "pygments" >> requirements.txt))
        run!(%(git add . ; git commit --allow-empty -m next))
        app.push!

        # Check the cache to have cleared
        expect(app.output).to match('Requirements file has been changed, clearing cached dependencies')
        expect(app.output).not_to match('No dependencies found, preparing to install')
        expect(app.output).not_to match('No change in requirements detected, installing from cache')

        # With no changes on redeploy, the cache should be present
        run!(%(git commit --allow-empty -m next))
        app.push!

        expect(app.output).to match('No change in requirements detected, installing from cache')
        expect(app.output).not_to match('Requirements file has been changed, clearing cached dependencies')
        expect(app.output).not_to match('No dependencies found, preparing to install')
      end
    end
  end

  it 'getting started app has no relative paths' do
    buildpacks = [
      :default,
      'https://github.com/sharpstone/force_absolute_paths_buildpack'
    ]
    new_app('python-getting-started', buildpacks: buildpacks).deploy do |app|
      # Deploy works
    end
  end
end
