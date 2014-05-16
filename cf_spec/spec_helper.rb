require 'bundler/setup'
require 'machete'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")