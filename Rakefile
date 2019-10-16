require 'bundler/gem_tasks'
require 'dotenv/tasks'
require 'teneo-data_model'
require 'erb'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'active_record'
require 'active_record/migration'

namespace :db do

  desc 'Set the environment variables'
  task environment: :dotenv do
    env = ENV['RUBY_ENV'] || 'development'
    db_config_file = ENV['DATABASE_CONFIG']
    # noinspection RubyResolve
    @db_config =  YAML.load(ERB.new(File.read(db_config_file)).result)[env.to_s]
    @db_admin_config = @db_config.merge('database' => 'postgres', 'schema_search_path' => 'public')
  end

  desc 'Create the database'
  task create: :environment do
    ActiveRecord::Base.establish_connection(@db_admin_config)
    ActiveRecord::Base.connection.create_database(@db_config['database'])
    puts "Database #{@db_config['database']} created."
  end

  desc 'Migrate the database'
  task migrate: :environment do
    ActiveRecord::Base.establish_connection(@db_config)
    ActiveRecord::Base.connection.migration_context.migrate
    Rake::Task['db:schema'].invoke
    puts "Database #{@db_config['database']} migrated."
  end

  desc 'Kill open DB connections'
  task kill_connections: :environment do
    db_name = @db_config['database']
    `psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='#{db_name}' AND pid <> pg_backend_pid();" -d '#{db_name}'`
    puts 'Database connections closed.'
  end

  desc 'Drop the database'
  task drop: :kill_connections do
    ActiveRecord::Base.establish_connection(@db_admin_config)
    ActiveRecord::Base.connection.drop_database(@db_config['database'])
    puts "Database #{@db_config['database']} deleted."
  rescue ActiveRecord::NoDatabaseError
    puts "Database #{@db_config['database']} does not exist."
  end

  desc 'Reset the database'
  task :reset => [:drop, :create, :migrate, :schema]

  desc 'Recreate the database'
  task :recreate => [:drop, :create, :migrate, :schema, :seed]

  desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  task :schema do
    ActiveRecord::Base.establish_connection(@db_config)
    require 'active_record/schema_dumper'
    filename = 'db/schema.rb'
    File.open(filename, 'w:utf-8') do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  desc 'Load the database seed files'
  task :seed, :environment do
    ActiveRecord::Base.establish_connection(@db_config)
    # noinspection RubyResolve
    load File.join(__dir__, 'db', 'seeds.rb')
  end

end

namespace :g do
  desc 'Generate migration'
  task :migration do
    name = ARGV[1] || raise('Specify name: rake g:migration your_migration')
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    path = File.expand_path("db/migrate/#{timestamp}_#{name}.rb", __dir__)
    migration_class = name.split('_').map(&:capitalize).join

    File.open(path, 'w') do |file|
      file.write <<~EOF
        class #{migration_class} < ActiveRecord::Migration
          def self.up
          end
          def self.down
          end
        end
      EOF
    end

    puts "Migration #{path} created"
    abort # needed stop other tasks
  end
end
