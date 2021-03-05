# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Python getting started project' do
  it 'getting started app has no relative paths' do
    buildpacks = [
      :default,
      'https://github.com/sharpstone/force_absolute_paths_buildpack'
    ]
    Hatchet::Runner.new('python-getting-started', buildpacks: buildpacks).deploy do |app|
      # Deploy works
    end
  end
end
