$: << 'cf_spec'
require "spec_helper"

describe 'deploying a python web app', :python_buildpack do
  it "makes the homepage available" do
    Machete.deploy_app("flask_web_app", :python) do |app|
      expect(app).to be_staged
      expect(app.homepage_html).to include "Hello, World!"
    end
  end

  if Machete::BuildpackMode.online?
    it "makes the homepage available" do
      Machete.deploy_app("flask_web_app_no_dependencies", :python) do |app|
        expect(app).to be_staged
        expect(app.homepage_html).to include "Hello, World!"
      end
    end
  end
end
