# frozen_string_literal: true
source "https://rubygems.org"

# Ingester
gem 'libis-format', '~> 2.0'
gem 'libis-metadata', '~> 1.0'
gem 'libis-workflow', '~> 3.0.beta'
gem 'kramdown'
gem 'time_difference'
gem 'sidekiq', '< 7'
gem 'mail'

# DataModel
gem 'activerecord'
gem 'activesupport'
gem 'symbolized'
gem 'ranked-model'
gem 'order_as_specified'
gem 'globalid'
gem 'dotenv'
gem 'method_source'
gem 'libis-tools'

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