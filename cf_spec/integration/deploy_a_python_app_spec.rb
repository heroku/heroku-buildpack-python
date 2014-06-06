$: << 'cf_spec'
require "spec_helper"

describe 'deploying a python web app' do
  it "successfully deploys apps with vendored dependencies" do
    Machete.deploy_app("flask_web_app") do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include "Hello, World!"
    end
  end

  it "successfully deploys apps without vendored depdendencies", if: Machete::BuildpackMode.online? do
    Machete.deploy_app("flask_web_app_not_vendored") do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include "Hello, World!"
    end
  end
end
