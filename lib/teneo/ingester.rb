# frozen_string_literal: true
require 'teneo/ingester/version'
require 'teneo/ingester/errors'

module Teneo
  module Ingester

    autoload :Config, 'teneo/ingester/config'
    autoload :Initializer, 'teneo/ingester/initializer'
    autoload :Database, 'teneo/ingester/database'
    autoload :Worker, 'teneo/ingester/worker'
    autoload :DummyWorker, 'teneo/ingester/workers/dummy_worker'
    autoload :StageWorker, 'teneo/ingester/workers/stage_worker'

    autoload :Task, 'teneo/ingester/task'

    autoload :FormatDatabase, 'teneo/ingester/format_database'
    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))

  end
end
