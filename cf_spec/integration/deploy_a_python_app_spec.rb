$: << 'cf_spec'
require 'spec_helper'

describe 'CF Python Buildpack' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:browser) { Machete::Browser.new(app) }

  context 'with cached buildpack dependencies' do
    context 'in an offline environment', if: Machete::BuildpackMode.offline? do
      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')

          expect(app.host).not_to have_internet_traffic
        end
      end

      context 'Warning when pip has mercurial dependencies' do
        let(:app_name) { 'mercurial_requirements' }

        specify do
          expect(app).not_to be_running(0)
          expect(app).to have_logged 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
          expect(app.host).to have_internet_traffic
        end
      end
    end
  end

  context 'without cached buildpack dependencies' do
    context 'in an online environment', if: Machete::BuildpackMode.online? do

      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
        end
      end

      context 'app has no dependencies' do
        let(:app_name) { 'flask_web_app_not_vendored' }

        specify do
          expect(app).to be_running

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
        end
      end
    end
  end
end
