require 'bundler/setup'
require 'machete'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")

RSpec.configure do |config|
  config.before(:suite) do
    Machete::BuildpackUploader.new(:python)
  end
end
