# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Heroku CI' do
  it 'works' do
    Hatchet::Runner.new('spec/fixtures/ci_nose').run_ci do |test_run|
      expect(test_run.output).to match('Downloading nose')
      expect(test_run.output).to match('OK')

      test_run.run_again

      expect(test_run.output).to match('installing from cache')
      expect(test_run.output).not_to match('Downloading nose')
    end
  end
end
