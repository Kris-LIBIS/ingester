# frozen_string_literal: true
source "https://rubygems.org"

# Ingester
gem 'libis-format', '~> 2.0'
gem 'libis-metadata', '~> 1.0'
gem 'teneo-data_model'
gem 'kramdown'
gem 'time_difference'
gem 'sidekiq', '< 7'
gem 'mail'

# Server
gem 'roda'

group :test do
  gem 'awesome_print'
  gem 'database_cleaner_2'
  gem 'rspec'
end

group :development do
  gem 'bundler'
  gem 'byebug' unless RUBY_PLATFORM == 'java'
  gem 'rake'
  gem 'tty-prompt'
  gem 'tty-spinner'
end