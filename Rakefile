# frozen_string_literal: true
$LOAD_PATH.unshift(File.join(__dir__, "lib"))
require "teneo/data_model"

require "dotenv"
require "erb"
require "active_record"
require "active_support"
require "awesome_print"

# ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
#   event = ActiveSupport::Notifications::Event.new(*args)
#   ap event.payload[:connection].instance_variable_get('@config').slice(:database, :username, :schema_search_path)
# end

namespace :db do
  desc "Set the environment variables"
  task :environment do
    env = ENV["APP_ENV"] || "development"
    Dotenv.load ".env"
    Dotenv.overload ".env.#{env}"
    # @logger ||= Logger.new(STDOUT)
    # ActiveRecord::Base.logger = @logger

    db_config_file = 'config/database.yml'
    # noinspection RubyResolve
    @db_config ||= YAML.load(ERB.new(File.read(db_config_file)).result)[env.to_s]
    ActiveRecord::Base.establish_connection(@db_config)
  end

  desc "Migrate the database"
  task migrate: "db:environment" do
    ActiveRecord::Base.establish_connection(@db_config)
    ActiveRecord::Base.connection.migration_context.migrate
    Rake::Task["db:schema"].invoke
    puts "Database #{@db_config["database"]} migrated."
  ensure
    ActiveRecord::Base.connection.close
  end

  desc "Create a db/schema.rb file that is portable against any DB supported by AR"
  task :schema do
    ActiveRecord::Base.establish_connection(@db_config)
    require "active_record/schema_dumper"
    filename = "db/schema.rb"
    File.open(filename, "w:utf-8") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Database schema dumped in #{filename}."
  ensure
    ActiveRecord::Base.connection.close
  end

  desc "Load the database seed files"
  task seed: "db:environment" do
    ActiveRecord::Base.establish_connection(@db_config)
    # noinspection RubyResolve
    load File.join("db", "seeds.rb")
  ensure
    ActiveRecord::Base.connection.close
  end
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task default: :spec
