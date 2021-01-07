# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Heroku CI' do
  it 'works' do
    before_deploy = proc do
      File.open('app.json', 'w+') do |f|
        f.puts <<~MANIFEST
          {
            "environments": {
              "test": {
                "scripts": {
                  "test": "nosetests"
                }
              }
            }
          }
        MANIFEST
      end

      run!('echo nose >> requirements.txt')
    end

    new_app('python_default', before_deploy: before_deploy).run_ci do |test_run|
      expect(test_run.output).to match('Downloading nose')
      expect(test_run.output).to match('OK')

      test_run.run_again

      expect(test_run.output).to match('installing from cache')
      expect(test_run.output).not_to match('Downloading nose')
    end
  end
end
