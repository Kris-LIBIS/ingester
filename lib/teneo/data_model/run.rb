# frozen_string_literal: true

require_relative 'base'
require_relative 'serializers/hash_serializer'
require_relative 'storage_resolver'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class Run < Base
    include Teneo::Workflow::Run

    self.table_name = 'runs'

    belongs_to :package
    belongs_to :user, optional: true
    has_many :status_logs, dependent: :destroy
    has_many :message_logs, inverse_of: :run, dependent: :destroy

    serialize :config, Serializers::HashSerializer
    serialize :options, Serializers::HashSerializer
    serialize :properties, Serializers::HashSerializer

    include StorageResolver

    def organization
      package&.organization
    end

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

    def execute(action = 'start', *args, **opts)
      result = super
      close_logger
      return result unless opts[:reporter]
      reporter = opts[:reporter].constantize&.new
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
      logger = Teneo::Workflow::Config.logger(self.name)
      return logger if logger
      unless ::Logging::Appenders[self.name]
        self.log_filename ||= File.join(log_dir, "#{self.name}.log")
        FileUtils.mkpath(File.dirname(self.log_filename))
        ::Logging::Appenders::file(
          self.name,
          filename: self.log_filename,
          layout: ::Teneo::Workflow::Config.get_log_formatter,
          level: self.log_level || 'DEBUG',
        )
      end
      logger = ::Teneo::Workflow::Config.logger(self.name, self.name)
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
