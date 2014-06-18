$: << 'cf_spec'
require 'spec_helper'

describe 'CF Python Buildpack' do
  subject(:app) { Machete.deploy_app(app_name) }

  context 'with cached buildpack dependencies' do
    context 'in an offline environment', if: Machete::BuildpackMode.offline? do
      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_staged
          expect(app.homepage_html).to include 'Hello, World!'
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
          expect(app).to be_staged
          expect(app.homepage_html).to include 'Hello, World!'
        end
      end

      context 'app has no dependencies' do
        let(:app_name) { 'flask_web_app_not_vendored' }

        specify do
          expect(app).to be_staged
          expect(app.homepage_html).to include 'Hello, World!'
        end
      end
    end
  end
end
