# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Python getting started project' do
  it 'builds successfully' do
    Hatchet::Runner.new('python-getting-started').deploy do |app|
      # Deploy works
    end
  end
end
