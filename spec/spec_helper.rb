require 'bundler/setup'
Bundler.setup

require 'rspec'
require 'teneo-ingester'
require 'database_cleaner'
ENV['RUBY_ENV'] = 'test'
Teneo::Ingester::Initializer.init

RSpec.configure do |config|

  # config.before(:suite) do
  #   DatabaseCleaner[:active_record].clean_with :truncation
  #   Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'), quiet: true)
  #   # DatabaseCleaner[:active_record].strategy = :transaction
  # end

  config.before(:each) do
    DatabaseCleaner[:active_record].clean_with :truncation
    Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'), quiet: true)
  end

  # config.around(:each) do |example|
  #   DatabaseCleaner[:active_record].cleaning do
  #     example.run
  #   end
  # end

end
