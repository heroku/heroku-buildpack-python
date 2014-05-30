$: << 'cf_spec'
require "spec_helper"

describe 'Mercurial Pip dependencies' do
  it "prints mercurial warning", if: Machete::BuildpackMode.offline? do
    Machete.deploy_app('mercurial_requirements', :python) do |app|
      expect(app).not_to be_staged
      expect(app.logs).to include 'Cloud Foundry does not support Pip Mercurial dependencies while in offline-mode. Vendor your dependencies if they do not work.'
    end
  end
end
