require 'bundler/setup'
Bundler.setup

require 'rspec'
require 'teneo-ingester'
require 'database_cleaner'
ENV['RUBY_ENV'] = 'test'

class Teneo::DataModel::Package
  def run_name
    'Run'
  end
end

Teneo::Ingester::Initializer.init

RSpec.configure do |config|

  if true
    config.before(:suite) do
      DatabaseCleaner[:active_record].clean_with :truncation
      Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'), quiet: true)
      DatabaseCleaner[:active_record].strategy = :transaction
    end

    config.around(:each) do |example|
      DatabaseCleaner[:active_record].cleaning do
        example.run
      end
    end
  else
    config.before(:each) do
      DatabaseCleaner[:active_record].clean_with :truncation
      Teneo::DataModel::SeedLoader.new(File.join(__dir__, 'seeds'), quiet: true)
    end
  end

  config.before :suite do
    Teneo::Ingester.configure do |cfg|
      taskdir = File.join(__dir__, 'tasks')
      Teneo::Ingester::Config.require_all taskdir
    end
  end

  config.before(:each) do
    Teneo::Ingester.configure do |cfg|
      cfg.logger.appenders =
          ::Logging::Appenders.string_io('StringIO', layout: ::Teneo::Ingester::Config.get_log_formatter, level: log_level)
      cfg.logger.add_appenders(
          ::Logging::Appenders.stdout('StdOut', layout: ::Teneo::Ingester::Config.get_log_formatter, level: :DEBUG)
      ) if false
    end
  end

end
