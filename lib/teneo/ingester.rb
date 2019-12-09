# frozen_string_literal: true
require 'teneo/ingester/version'
require 'teneo/ingester/errors'

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
    autoload :Representation, 'teneo/ingester/representation'
    autoload :SeedLoader, 'teneo/ingester/seed_loader'
    autoload :WorkItem, 'teneo/ingester/work_item'
    # autoload :Worker, 'teneo/ingester/worker'
    # autoload :DummyWorker, 'teneo/ingester/workers/dummy_worker'
    # autoload :StageWorker, 'teneo/ingester/workers/stage_worker'

    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(__dir__, '..', '..'))

    RAKEFILE = File.join(File.expand_path(__dir__), 'ingester', 'rake', 'Rakefile')

  end
end
