$: << 'cf_spec'
require "spec_helper"

describe 'Mercurial Pip dependencies' do

  if Machete::BuildpackMode.offline?
    specify do
      Machete.deploy_app('mercurial_requirements', :python) do |app|
        expect(app).to be_staged
        expect(app.staging_log).to include 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
      end
    end
  end

  if Machete::BuildpackMode.online?
    specify do
      Machete.deploy_app('mercurial_requirements', :python) do |app|
        expect(app).to be_staged
        expect(app.staging_log).not_to include 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
      end
    end
  end
end
