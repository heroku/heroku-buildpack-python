require 'spec_helper'

describe 'CF Python Buildpack' do
  let(:browser)  { Machete::Browser.new(app) }
  let(:app_name) { 'flask_web_app' }

  subject(:app)  { Machete.deploy_app(app_name) }

  after { Machete::CF::DeleteApp.new.execute(app) }

  def create_environment_yml(app_name,contents = nil)
    filename = File.join(File.dirname(__FILE__), '..', 'fixtures', app_name, 'environment.yml')
    unless contents
      contents = <<HERE
name: pydata_test
dependencies:
- pip
- pytest
- flask
- nose
- numpy=1.10.4
- scipy=0.17.0
- scikit-learn=0.17.1
- pandas=0.18.0
HERE
    end
    File.open(filename, 'w') { |file| file.write(contents) }
  end

  context 'with an unsupported dependency' do
    let(:app_name) { 'unsupported_version' }

    it 'displays a nice error messages and gracefully fails' do
      expect(app).to_not be_running
      expect(app).to_not have_logged 'Downloaded ['
      expect(app).to have_logged 'DEPENDENCY MISSING IN MANIFEST: python 99.99.99'
    end
  end

  it "should not display the allow-all-external deprecation message" do
    expect(app).to be_running
    expect(app).to_not have_logged 'DEPRECATION: --allow-all-external has been deprecated and will be removed in the future'
  end

  context 'with cached buildpack dependencies', :cached do
    context 'app has dependencies' do
      context 'with Python 2' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running(60)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
          expect(app).to have_logged(/Downloaded \[file:\/\/.*\]/)

          expect(app).not_to have_internet_traffic
        end
      end

      context 'with Python 3' do
        let(:app_name) { 'flask_web_app_python_3' }

        specify do
          expect(app).to be_running(120)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')

          expect(app).not_to have_internet_traffic
        end
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
        expect(app).to have_logged 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
      end
    end
  end

  context 'without cached buildpack dependencies', :uncached do
    context 'app has dependencies' do
      context 'with Python 2' do
        let(:app_name) { 'flask_web_app' }

        specify do
          expect(app).to be_running(60)
          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
          expect(app).to have_logged(/Downloaded \[https:\/\/.*\]/)
        end
      end

      context 'with Python 3' do
        let(:app_name) { 'flask_web_app_python_3' }

        specify do
          expect(app).to be_running(60)

          browser.visit_path('/')
          expect(browser).to have_body('Hello, World!')
        end
      end
    end

    context 'app has non-vendored dependencies' do
      let(:app_name) { 'flask_web_app_not_vendored' }

      specify do
        expect(app).to be_running(60)

        browser.visit_path('/')
        expect(browser).to have_body('Hello, World!')
      end

      it "uses a proxy during staging if present" do
        expect(app).to use_proxy_during_staging
      end
    end

    context 'an app that uses miniconda and python 2' do
      let(:app_name) { 'miniconda_simple_app_python_2' }

      specify do
        expect(app).to be_running(120)

        browser.visit_path('/')
        expect(browser).to have_body('numpy: 1.10.4')
        expect(browser).to have_body('scipy: 0.17.0')
        expect(browser).to have_body('sklearn: 0.17.1')
        expect(browser).to have_body('pandas: 0.18.0')
        expect(browser).to have_body('python-version2')
      end

      it "uses a proxy during staging if present" do
        expect(app).to use_proxy_during_staging
      end
    end

    context 'an app that uses miniconda and python 3' do
      let(:app_name) { 'miniconda_simple_app_python_3' }
      before(:each) { create_environment_yml app_name }
      after(:each) {create_environment_yml app_name}

      describe 'keeping track of environment.yml' do
        specify do
          expect(app).to be_running(120)

          browser.visit_path('/')
          expect(browser).to have_body('numpy: 1.10.4')
          expect(browser).to have_body('scipy: 0.17.0')
          expect(browser).to have_body('sklearn: 0.17.1')
          expect(browser).to have_body('pandas: 0.18.0')
          expect(browser).to have_body('python-version3')
        end

        it "doesn't re-download unchanged dependencies" do
          expect(app).to be_running(120)
          Machete.push(app)
          expect(app).to be_running(120)
          expect(app).to have_logged("Using dependency cache")
        end

        it "it updates dependencies if environment.yml changes" do
          contents = <<HERE
name: pydata_test
dependencies:
- pip
- pytest
- flask
- nose
- numpy=1.11.0
- scikit-learn=0.17.1
- pandas=0.18.0
HERE
          create_environment_yml app_name, contents
          Machete.push(app)
          expect(app).to be_running(120)

          browser.visit_path('/')
          expect(browser).to have_body('numpy: 1.11.0')
        end

        it "uses a proxy during staging if present" do
          expect(app).to use_proxy_during_staging
        end
      end
    end

    context 'an app that uses miniconda and specifies python 2 in runtime.txt but python3 in the environment.yml' do
      let(:app_name) { 'miniconda_simple_app_python_2_3' }

      specify do
        expect(app).to be_running(120)

        browser.visit_path('/')
        expect(browser).to have_body('python-version3')
        expect(app).to have_logged "WARNING: you have specified the version of Python runtime both in 'runtime.txt' and 'environment.yml'. You should remove one of the two versions"
      end

      it "uses a proxy during staging if present" do
        expect(app).to use_proxy_during_staging
      end
    end
  end
end
