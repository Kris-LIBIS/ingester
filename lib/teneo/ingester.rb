# frozen_string_literal: true

require 'teneo/data_model'

module Teneo
  module Ingester
    autoload :Config, 'teneo/ingester/config'
    autoload :ConversionRunner, 'teneo/ingester/conversion_runner'
    autoload :Database, 'teneo/ingester/database'
    autoload :FormatDatabase, 'teneo/ingester/format_database'
    autoload :Initializer, 'teneo/ingester/initializer'
    autoload :TaskLoader, 'teneo/ingester/task_loader'

    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.expand_path('../..', __dir__)

    def self.root
      ROOT_DIR
    end
  end
end
