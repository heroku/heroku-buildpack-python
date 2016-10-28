require 'spec_helper'

describe 'deploying a flask web app' do
  let(:browser)  { Machete::Browser.new(app) }
   let(:app_name) { 'flask_web_app_python_3_no_procfile' }

  subject(:app)  { Machete.deploy_app(app_name) }

  after { Machete::CF::DeleteApp.new.execute(app) }

  context 'start command is specified in manifest.yml' do
    specify do
      expect(app).to be_running(60)

      browser.visit_path('/')
      expect(browser).to have_body('I was started without a Procfile')
    end
  end
end
