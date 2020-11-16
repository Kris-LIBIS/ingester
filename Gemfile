# frozen_string_literal: true
source "https://rubygems.org"

app = ENV["APP"]
# Ingester
if app == "worker"
  gem "libis-format", "~> 2.0"
  gem "libis-metadata", "~> 1.0"
  gem "kramdown"
  gem "time_difference"
  gem "sidekiq", "< 7"
  gem "mail"
end

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

# Workflow
gem "ruby-enum"

# API Server
if app == "api"
  gem "roda"
end

# Admin Server
if app == "server"
  gem "rails"
  gem "bootsnap", ">= 1.1.0", require: false
  gem "puma"
  gem "sass-rails"
  gem "turbolinks"
  group :development do
    gem "byebug" unless RUBY_PLATFORM == "java"
    gem "web-console"
    gem "listen", ">= 3.0.5", "< 3.2"
    gem "spring"
    gem "spring-watcher-listen", "~> 2.0.0"
  end
end

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
