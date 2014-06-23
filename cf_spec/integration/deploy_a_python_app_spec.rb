$: << 'cf_spec'
require 'spec_helper'

describe 'CF Python Buildpack' do
  subject(:app) { Machete.deploy_app(app_name) }

  context 'with cached buildpack dependencies' do
    context 'in an offline environment', if: Machete::BuildpackMode.offline? do
      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running
          expect(app.homepage_html).to include 'Hello, World!'
          expect(app).to have_no_internet_traffic
        end
      end

      context 'Warning when pip has mercurial dependencies' do
        let(:app_name) { 'mercurial_requirements' }

        specify do
          expect(app).to be_running
          expect(app.logs).to include 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
          expect(app).to have_no_internet_traffic
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
          expect(app.homepage_html).to include 'Hello, World!'
        end
      end

      context 'app has no dependencies' do
        let(:app_name) { 'flask_web_app_not_vendored' }

        specify do
          expect(app).to be_running
          expect(app.homepage_html).to include 'Hello, World!'
        end
      end
    end
  end

end
