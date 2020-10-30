# frozen_string_literal: true
source "https://rubygems.org"

# Ingester
gem "libis-format", "~> 2.0"
gem "libis-metadata", "~> 1.0"
gem "kramdown"
gem "time_difference"
gem "sidekiq", "< 7"
gem "mail"

# DataModel
gem "activerecord"
gem "activesupport"
gem "bcrypt"
gem "ranked-model"
gem "symbolized"
gem "order_as_specified"
gem "globalid"
gem "dotenv"
gem "method_source"
gem "libis-tools"

if RUBY_PLATFORM == "java"
  gem "activerecord-jdbcpostgresql-adapter"
else
  gem "active_record_extended"
  gem "pg"
end

# Server
gem "roda"

# Global
group :test do
  gem "awesome_print"
  gem "database_cleaner_2"
  gem "rspec"
end

group :development do
  gem "bundler"
  gem "byebug" unless RUBY_PLATFORM == "java"
  gem "rake"
  gem "tty-prompt"
  gem "tty-spinner"
end
