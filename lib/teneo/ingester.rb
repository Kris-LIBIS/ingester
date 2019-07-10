# frozen_string_literal: true
require 'teneo/ingester/version'

module Teneo
  module Ingester

    class Error < StandardError;
    end

    autoload :Config, 'teneo/ingester/config'
    autoload :Initializer, 'teneo/ingester/initializer'
    autoload :Database, 'teneo/ingester/database'
    autoload :Worker, 'teneo/ingester/worker'
    autoload :DummyWorker, 'teneo/ingester/workers/dummy_worker'

    autoload :FormatDatabase, 'teneo/ingester/format_database'
    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))

  end
end
