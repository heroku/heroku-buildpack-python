# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Django support' do
  context 'when requirements.txt contains Django==1.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_django_1.11') }

    it 'warns about Django end of support' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing requirements with pip
          remote:  !     Your Django version is nearing the end of its community support.
          remote:  !     Upgrade to continue to receive security updates and for the best experience with Django.
          remote:  !     For more information, check out https://www.djangoproject.com/download/#supported-versions
        OUTPUT
      end
    end
  end

  context 'when requirements.txt contains Django==2.1' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/requirements_django_2.1') }

    it 'does not warn about Django end of support' do
      app.deploy do |app|
        expect(app.output).not_to include('https://www.djangoproject.com/download/#supported-versions')
      end
    end
  end

  # TODO: Add tests for disabling collectstatic, failure cases etc.
  context 'when building a Django project' do
    let(:app) { Hatchet::Runner.new('python-getting-started') }

    it 'collectstatic is run automatically' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> \\$ python manage.py collectstatic --noinput
          remote:        \\d+ static files copied to '/tmp/build_.*/staticfiles', \\d+ post-processed.
        REGEX
      end
    end
  end
end
