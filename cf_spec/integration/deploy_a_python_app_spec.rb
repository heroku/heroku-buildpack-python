$: << 'cf_spec'
require "spec_helper"

describe 'deploying a python web app' do
  it "makes the homepage available for a flask web app" do
    Machete.deploy_app("flask_web_app", :python) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include "Hello, World!"
    end
  end

  it "makes the homepage available for a flask web app without dependencies", if: Machete::BuildpackMode.online? do
    Machete.deploy_app("flask_web_app_no_dependencies", :python) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include "Hello, World!"
    end
  end
end
