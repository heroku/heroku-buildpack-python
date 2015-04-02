$: << 'cf_spec'
require 'spec_helper'

describe 'CF Python Buildpack' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:browser) { Machete::Browser.new(app) }

  describe 'switching stacks' do
    subject(:app) { Machete.deploy_app(app_name, stack: 'lucid64') }
    let(:app_name) { 'flask_web_app_not_vendored' }

    specify do
      expect(app).to be_running(60)

      browser.visit_path('/')
      expect(browser).to have_body('Hello, World!')

      replacement_app = Machete::App.new(app_name, Machete::Host.create, stack: 'cflinuxfs2')

      app_push_command = Machete::CF::PushApp.new
      app_push_command.execute(replacement_app)

      expect(replacement_app).to be_running(60)

      browser.visit_path('/')
      expect(browser).to have_body('Hello, World!')

    end
  end

  context 'with cached buildpack dependencies' do
    context 'in an offline environment', if: Machete::BuildpackMode.offline? do
      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running(60)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')

          expect(app.host).not_to have_internet_traffic
        end
      end

      context 'Warning when pip has mercurial dependencies' do
        let(:log_file) { File.open('log/integration.log', 'r') }
        let(:app_name) { 'mercurial_requirements' }

        before do
          log_file.readlines
        end

        specify do
          expect(app).not_to be_running(0)
          statement_appearances = log_file.readlines.join.scan 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
          expect(statement_appearances.count).to be 1
        end
      end
    end
  end

  context 'without cached buildpack dependencies' do
    context 'in an online environment', if: Machete::BuildpackMode.online? do

      context 'app has dependencies' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running(60)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
        end
      end

      context 'app has no dependencies' do
        let(:app_name) { 'flask_web_app_not_vendored' }

        specify do
          expect(app).to be_running(60)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
        end
      end
    end
  end
end
