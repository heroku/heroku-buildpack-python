# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Python' do
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

  describe 'python versions' do
    it 'works with 3.7.9' do
      version = '3.7.9'
      before_deploy = -> { run!(%(echo "python-#{version}" >> runtime.txt)) }
      new_app('python_default', before_deploy: before_deploy).deploy do |app|
        expect(app.run('python -V')).to match(version)
      end
    end

    it 'works with 3.8.7' do
      version = '3.8.7'
      before_deploy = -> { run!(%(echo "python-#{version}" >> runtime.txt)) }
      new_app('python_default', before_deploy: before_deploy).deploy do |app|
        expect(app.run('python -V')).to match(version)
      end
    end

    it 'fails with a bad version' do
      version = '3.8.2.lol'
      before_deploy = -> { run!(%(echo "python-#{version}" >> runtime.txt)) }
      new_app('python_default', before_deploy: before_deploy, allow_failure: true).deploy do |app|
        expect(app.output).to match('not available for this stack')
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
