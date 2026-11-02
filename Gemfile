# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.4', '< 4.1'

group :test, :development do
  gem 'heroku_hatchet'
  # Hatchet's `threaded` dependency requires `logger` without declaring it.
  gem 'logger'
  gem 'parallel_split_test'
  gem 'rspec-core'
  gem 'rspec-expectations'
  gem 'rspec-retry'
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end
