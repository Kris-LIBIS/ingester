# frozen_string_literal: true

require 'dotenv'

require 'teneo/ingester'
require 'libis-tools'
require 'libis-format'
# require 'libis/tools/extend/hash'

require 'sidekiq'
require 'sidekiq/api'

require 'active_support'

require 'singleton'

module Teneo
  module Ingester

    # noinspection RubyResolve
    class Initializer
      include Singleton

      def initialize
        @database = nil
        @crypt = nil
        @config = nil
        ENV['APP_ENV'] ||= 'development'
        #noinspection RubyArgCount
        Dotenv.load
      end

      def self.init
        # initializers
        # noinspection RubyResolve
        ::Teneo::Ingester::Config.require_all(File.join Teneo::Ingester::ROOT_DIR, 'config', 'initializers')

        initializer = self.instance
        initializer.configure
        initializer.database
        initializer.sidekiq
        initializer
      end

      def configure

        ::Teneo::Ingester.configure do |cfg|
          config.config&.each do |key, value|
            if value.is_a?(Hash)
              cfg[key].merge!(value)
            else
              cfg.send("#{key}=", value)
            end
          end
        end

        if config.ingester&.task_dir
          ::Teneo::Ingester::Config.require_all(config.ingester.task_dir)
        end

        if config.ingester&.converter_dir
          ::Teneo::Ingester::Config.require_all(config.ingester.converter_dir)
        end

        if config.mail
          require 'mail'
          opts = {}
          opts[:address] = @config.mail.host if @config.mail.host
          opts[:port] = @config.mail.port if @config.mail.port
          Mail.defaults do
            delivery_method :smtp, opts
          end
        end

        self
      end

      def load_tasks_and_converters
        Teneo::Ingester::SeedLoader.new('.', quiet: true)
      end

      def database
        @database ||= begin
                        db = ::Teneo::Ingester::Database.new(ENV['DATABASE_CONFIG'], ENV['APP_ENV'])
                        db.connect
                        db
                      end
      end

      def sidekiq_client
        raise RuntimeError, 'Missing sidekiq section in configuration.' unless config.sidekiq

        id = (config.sidekiq.namespace.gsub(/\s/, '') || 'Ingester' rescue 'Ingester')

        Sidekiq.configure_client do |cfg|
          cfg.redis = {
              url: ENV['REDIS_URL'] || config.sidekiq.redis_url,
              namespace: ENV['REDIS_NAMESPACE'] || config.sidekiq.namespace,
              id: "#{id}Client"
          }.cleanup
        end
      end

      def sidekiq_server
        raise RuntimeError, 'Missing sidekiq section in configuration.' unless config.sidekiq

        id = (config.sidekiq.namespace.gsub(/\s/, '') || 'Ingester' rescue 'Ingester')

        Sidekiq.configure_server do |cfg|
          cfg.redis = {
              url: config.sidekiq.redis_url,
              namespace: config.sidekiq.namespace,
              id: "#{id}Server"
          }.cleanup
        end

      end

      def sidekiq
        sidekiq_server
        sidekiq_client
      end

      def self.encrypt(text, purpose: nil)
        self.instance.encrypt(text, purpose: purpose)
      end

      def self.decrypt(text, purpose: nil)
        self.instance.decrypt(text, purpose: purpose)
      end

      def encrypt(text, purpose: nil)
        options = {}
        options[:purpose] = purpose if purpose
        crypt.encrypt_and_sign(text, **options)
      end

      def decrypt(text, purpose: nil)
        options = {}
        options[:purpose] = purpose if purpose
        crypt.decrypt_and_verify(text, **options)
      end

      private

      def config
        @config ||= begin
                      config_file = ENV['SITE_CONFIG']
                      raise RuntimeError, "Configuration file '#{config_file}' not found." unless File.exist?(config_file)
                      load_config(config_file)
                    end
      end

      def crypt
        @crypt ||= begin
                     key = File.open(File.join(ROOT_DIR, 'key.bin'), 'rb') { |f| f.read(32) }
                     raise RuntimeError, "Encryption key could not be read." unless key
                     ActiveSupport::MessageEncryptor.new(key)
                   end
      end

      def load_config(config_file)
        cfg = Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
        cfg << config_file
      end

    end

  end
end
