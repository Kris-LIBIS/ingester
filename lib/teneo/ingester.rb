# frozen_string_literal: true
require "teneo/errors"
require "teneo/ingester/version"

#noinspection RubyResolve
require "teneo/ingester/rake/railtie" if defined?(Rails)

module Teneo
  module Ingester
    autoload :Config, "teneo/ingester/config"
    autoload :ConversionRunner, "teneo/ingester/conversion_runner"
    autoload :Database, "teneo/ingester/database"
    autoload :FormatDatabase, "teneo/ingester/format_database"
    autoload :Initializer, "teneo/ingester/initializer"
    autoload :TaskLoader, "teneo/ingester/task_loader"

    FormatDatabase.register

    def self.configure
      yield ::Teneo::Ingester::Config.instance
    end

    ROOT_DIR = File.absolute_path(File.join(__dir__, "..", ".."))

    def self.root
      File.expand_path("../..", __dir__)
    end
  end
end
