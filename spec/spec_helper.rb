require 'bundler/setup'
Bundler.setup

require 'rspec'
require 'teneo-ingester'
require 'database_cleaner/active_record'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'))
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
