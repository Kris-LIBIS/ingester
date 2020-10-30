require 'dotenv/tasks'
require 'erb'
require 'active_record'
require 'active_support'
require 'awesome_print'

# ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
#   event = ActiveSupport::Notifications::Event.new(*args)
#   ap event.payload[:connection].instance_variable_get('@config').slice(:database, :username, :schema_search_path)
# end

namespace :teneo do
  namespace :db do

    desc 'Set the environment variables'
    task environment: :dotenv do
      # @logger ||= Logger.new(STDOUT)
      # ActiveRecord::Base.logger = @logger

      env = ENV['RUBY_ENV'] || 'development'
      db_config_file = ENV['DATABASE_CONFIG']
      # noinspection RubyResolve
      @db_config ||= YAML.load(ERB.new(File.read(db_config_file)).result)[env.to_s]
      # #noinspection RubyStringKeysInHashInspection
      @db_config_dba ||= @db_config.merge(
        {
          'username' => @db_config['dba_name'],
          'password' => @db_config['dba_pass'],
          'migrations_paths' => @db_config['dba_migrations_paths']
        }
      )
      # #noinspection RubyStringKeysInHashInspection
      @db_config_admin ||= @db_config_dba.merge(
        {
          'database' => 'postgres',
          'schema_search_path' => 'public',
        }
      )
      ActiveRecord::Base.establish_connection(@db_config)
    end

    desc 'Kill open DB connections'
    task kill_connections: 'teneo:db:environment' do
      db_name = @db_config['database']
      `psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='#{db_name}' AND pid <> pg_backend_pid();" -d '#{db_name}'`
      puts 'Database connections closed.'
    end

    desc 'Drop the database'
    task drop: 'teneo:db:kill_connections' do
      ActiveRecord::Base.establish_connection(@db_config_admin)
      # ActiveRecord::Base.connection_handler.retrieve_connection('dba').drop_database(@db_config['database'])
      # ActiveRecord::Base.establish_connection(@db_config_admin)
      ActiveRecord::Base.connection.drop_database(@db_config['database'])
      puts "Database #{@db_config['database']} deleted."
    rescue ActiveRecord::NoDatabaseError
      puts "Database #{@db_config['database']} does not exist."
    ensure
      ActiveRecord::Base.connection.close
    end

    desc 'Create the database'
    task create: 'teneo:db:environment' do
      ActiveRecord::Base.establish_connection(@db_config_admin)
      ActiveRecord::Base.connection.create_database(@db_config['database'], owner: @db_config_admin['username'])
      puts "Database #{@db_config['database']} created."
    ensure
      ActiveRecord::Base.connection.close
    end

    desc 'Enable the extensions'
    task extensions: 'teneo:db:environment' do
      ActiveRecord::Base.establish_connection(@db_config_dba)
      ActiveRecord::Base.connection.migration_context.migrate
      puts "Extensions enabled."
      ActiveRecord::Base.connection.execute("GRANT ALL ON TABLE schema_migrations TO #{@db_config['username']};")
      ActiveRecord::Base.connection.execute("GRANT ALL ON TABLE ar_internal_metadata TO #{@db_config['username']};")
    ensure
      ActiveRecord::Base.connection.close
    end

    desc 'Migrate the database'
    task migrate: %w(teneo:db:environment teneo:db:extensions) do
      ActiveRecord::Base.establish_connection(@db_config)
      ActiveRecord::Base.connection.migration_context.migrate
      Rake::Task['teneo:db:schema'].invoke
      puts "Database #{@db_config['database']} migrated."
    ensure
      ActiveRecord::Base.connection.close
    end

    desc 'Reset the database'
    task reset: %w(teneo:db:drop teneo:db:create teneo:db:migrate teneo:db:schema)

    desc 'Recreate the database'
    task recreate: %w(teneo:db:drop teneo:db:create teneo:db:migrate teneo:db:schema teneo:db:seed)

    desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
    task :schema do
      ActiveRecord::Base.establish_connection(@db_config)
      require 'active_record/schema_dumper'
      filename = 'db/schema.rb'
      File.open(filename, 'w:utf-8') do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      puts "Database schema dumped in #{filename}."
    ensure
      ActiveRecord::Base.connection.close
    end

    desc 'Load the database seed files'
    task seed: 'teneo:db:environment' do
      ActiveRecord::Base.establish_connection(@db_config)
      # noinspection RubyResolve
      load File.join('db', 'seeds.rb')
    ensure
      ActiveRecord::Base.connection.close
    end

  end
end