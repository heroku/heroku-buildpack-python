# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.2', '< 3.4'

group :test, :development do
  gem 'heroku_hatchet'
  # Work around https://github.com/excon/excon/issues/860
  gem 'logger'
  gem 'parallel_split_test'
  gem 'rspec-core'
  gem 'rspec-expectations'
  gem 'rspec-retry'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end
