# frozen_string_literal: true
require 'teneo/ingester/version'
require 'teneo/ingester/errors'

#noinspection RubyResolve
require 'teneo/ingester/rake/railtie' if defined?(Rails)

require 'teneo/ingester/workflow/all_injectors'

module Teneo
  module Ingester

    autoload :Collection, 'teneo/ingester/collection'
    autoload :Config, 'teneo/ingester/config'
    autoload :Container, 'teneo/ingester/container'
    autoload :ConversionRunner, 'teneo/ingester/conversion_runner'
    autoload :Database, 'teneo/ingester/database'
    autoload :DirItem, 'teneo/ingester/dir_item'
    autoload :FileItem, 'teneo/ingester/file_item'
    autoload :FormatDatabase, 'teneo/ingester/format_database'
    autoload :Initializer, 'teneo/ingester/initializer'
    autoload :IntellectualEntity, 'teneo/ingester/intellectual_entity'
    autoload :ItemGroup, 'teneo/ingester/item_group'
    autoload :Queue, 'teneo/ingester/queue'
    autoload :Representation, 'teneo/ingester/representation'
    autoload :SeedLoader, 'teneo/ingester/seed_loader'
    autoload :Work, 'teneo/ingester/work'
    autoload :WorkItem, 'teneo/ingester/work_item'
    autoload :WorkStatus, 'teneo/ingester/work_status'
    autoload :Worker, 'teneo/ingester/worker'

    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(__dir__, '..', '..'))

    def self.root
      File.expand_path('../..', __dir__)
    end

    def self.migrations_path
      [
          Teneo::DataModel.migrations_path,
          File.join(root, 'db', 'migrate')
      ]
    end

    def self.dba_migrations_path
      [
          Teneo::DataModel.dba_migrations_path,
      ]
    end

    RAKEFILE = File.join(File.expand_path(__dir__), 'ingester', 'rake', 'Rakefile')

  end
end
