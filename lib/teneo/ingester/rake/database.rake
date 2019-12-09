namespace :teneo do
  namespace :db do

    Rake::Task[:environment].enhance do
      #noinspection RubyStringKeysInHashInspection
      @db_config_dba = @db_config.merge(
          {
              'schema_search_path' => 'public',
              'username' => @db_config['dba_name'],
              'password' => @db_config['dba_pass'],
          }
      )
    end

    desc 'Create database schema'
    task create_schema: 'teneo:db:environment' do
      if @db_config['data_schema']
        ActiveRecord::Base.establish_connection(@db_config_dba)
        conn = ActiveRecord::Base.connection
        schema_name = @db_config['data_schema']
        conn.execute("CREATE SCHEMA \"#{schema_name}\" AUTHORIZATION #{db_config['username']}")
        puts "Database Schema #{schema_name} created."
      end
    end

    # Add create_schema actions to create task
    Rake::Task['teneo:db:create'].enhance do
      Rake::Task['teneo:db:create_schema'].invoke
    end

    desc 'Drop database schema'
    task drop_schema: 'teneo:db:environment' do
      if @db_config['data_schema']
        ActiveRecord::Base.establish_connection(@db_config_dba)
        conn = ActiveRecord::Base.connection
        schema_name = @db_config['username']
        conn.drop_schema(schema_name, if_exists: true)
        puts "Database Schema #{schema_name} deleted."
      end
    rescue ActiveRecord::NoDatabaseError
      puts "Database #{@db_config['database']} does not exist."
    end

    # Add drop_schema dependency to drop task
    Rake::Task['teneo:db:drop'].enhance ['teneo:db:drop_schema']

  end
end
