# frozen_string_literal: true

require 'teneo/data_model/run'
require 'teneo/ingester/tasks/base/reporter'

module Teneo::DataModel

  class Run

    include Libis::Workflow::Run

    before_destroy :delete_ingest_dir

    def delete_ingest_dir
      FileUtils.rmtree(ingest_dir) if Dir.exists?(ingest_dir)
    end

    def delete_log
      log_file = self.log_filename
      #noinspection RubyArgCount
      FileUtils.rm(log_file) if log_file && !log_file.blank? && File.exist?(log_file)
    end

    def ingest_dir
      package.ingest_dir
    end

    def job
      package
    end

    def run
      self
    end

    def names
      []
    end

    def execute(action = 'start', *args)
      result = super
      close_logger
      reporter = Teneo::Ingester::Tasks::Base::Reporter.new
      reporter.parent = self
      reporter.process(package)
      result
    end

    def submitter(v = nil)
      options[:submitter] = v unless v.nil?
      options[:submitter] || 'kris.dekeyser@libis.be'
    end

    def log_dir
      package.log_dir
    end

    def logger
      logger = ::Logging::Repository.instance[self.name]
      return logger if logger
      unless ::Logging::Appenders[self.name]
        self.log_filename ||= File.join(log_dir,"#{self.name}.log")
        FileUtils.mkpath(File.dirname(self.log_filename))
        ::Logging::Appenders::File.new(
            self.name,
            filename: self.log_filename,
            layout: ::Teneo::Ingester::Config.get_log_formatter,
            level: self.log_level || 'DEBUG'
        )
      end
      logger = ::Teneo::Ingester::Config.logger(self.name, self.name)
      logger.additive = false
      logger.level = self.log_level || 'DEBUG'
      logger
    end

    def close_logger
      return unless self.log_to_file
      ::Logging::Appenders[self.name].close
      ::Logging::Appenders.remove(self.name)
      ::Logging::Repository.instance.delete(self.name)
    end

  end
end
