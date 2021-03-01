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
          remote:        More info: https://devcenter.heroku.com/articles/buildpacks#detection-failure
        OUTPUT
      end
    end
  end
end
