# frozen_string_literal: true
require 'dotenv'

require 'teneo-ingester'
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

      attr_accessor :config

      def initialize
        key = File.open(File.join(ROOT_DIR, 'key.bin'), 'rb') { |f| f.read(32) }
        raise RuntimeError, "Encryption key could not be read." unless key
        @crypt = ActiveSupport::MessageEncryptor.new(key)

        @config = nil
      end

      def self.init
        ENV['RUBY_ENV'] ||= 'development'

        unless ENV['RUBY_ENV'] == 'production'
          #noinspection RubyArgCount
          Dotenv.load
          Dotenv.require_keys %w'SITE_CONFIG DATABASE_CONFIG'
        end

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

        config_file = ENV['SITE_CONFIG']

        raise RuntimeError, "Configuration file '#{config_file}' not found." unless File.exist?(config_file)

        load_config(config_file)

        ::Teneo::Ingester.configure do |cfg|
          @config.config&.each do |key, value|
            if value.is_a?(Hash)
              cfg[key].merge!(value)
            else
              cfg.send("#{key}=", value)
            end
          end
        end

        if @config.ingester&.task_dir
          ::Teneo::Ingester::Config.require_all(@config.ingester.task_dir)
        end

        if @config.ingester&.converter_dir
          ::Teneo::Ingester::Config.require_all(@config.ingester.converter_dir)
        end

        if @config.mail
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

        return @database if @database

        @database = ::Teneo::Ingester::Database.new(ENV['DATABASE_CONFIG'], ENV['RUBY_ENV'])
        @database.connect
        @database

      end

      def sidekiq

        raise RuntimeError, 'Missing sidekiq section in configuration.' unless @config && @config.sidekiq

        id = (@config.sidekiq.namespace.gsub(/\s/, '') || 'Ingester' rescue 'Ingester')

        Sidekiq.configure_client do |config|
          config.redis = {
              url: @config.sidekiq.redis_url,
              namespace: @config.sidekiq.namespace,
              id: "#{id}Client"
          }.cleanup
        end

        Sidekiq.configure_server do |config|
          config.redis = {
              url: @config.sidekiq.redis_url,
              namespace: @config.sidekiq.namespace,
              id: "#{id}Server"
          }.cleanup
        end

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
        @crypt.encrypt_and_sign(text, **options)
      end

      def decrypt(text, purpose: nil)
        options = {}
        options[:purpose] = purpose if purpose
        @crypt.decrypt_and_verify(text, **options)
      end

      private

      def load_config(config_file)

        @config ||= Libis::Tools::ConfigFile.new({}, preserve_original_keys: false)
        @config << config_file

      end

    end

  end
end
