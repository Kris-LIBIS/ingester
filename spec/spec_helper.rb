require 'bundler/setup'
Bundler.setup

require 'rspec'
require 'teneo-ingester'
require 'database_cleaner'
ENV['RUBY_ENV'] = 'test'

RSpec.configure do |config|

  config.before(:suite) do
    Teneo::Ingester::Initializer.init
    DatabaseCleaner[:active_record].clean_with :truncation
    Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'), tty: false)
    DatabaseCleaner[:active_record].strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner[:active_record].cleaning do
      example.run
    end
  end

end
