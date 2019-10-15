# frozen_string_literal: true
require 'teneo/ingester/version'
require 'teneo/ingester/errors'

module Teneo
  module Ingester

    autoload :Config, 'teneo/ingester/config'
    autoload :Database, 'teneo/ingester/database'
    autoload :DirItem, 'teneo/ingester/dir_item'
    autoload :FileItem, 'teneo/ingester/file_item'
    autoload :FormatDatabase, 'teneo/ingester/format_database'
    autoload :Initializer, 'teneo/ingester/initializer'
    autoload :Task, 'teneo/ingester/task'
    autoload :WorkItem, 'teneo/ingester/work_item'
    # autoload :Worker, 'teneo/ingester/worker'
    # autoload :DummyWorker, 'teneo/ingester/workers/dummy_worker'
    # autoload :StageWorker, 'teneo/ingester/workers/stage_worker'

    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))

  end
end
