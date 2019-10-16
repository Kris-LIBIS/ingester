require 'active_record'
require 'teneo-ingester'
require 'libis/tools/extend/hash'
require 'erb'

module Teneo
  module Ingester
    class Database
      include ::Libis::Tools::Logger

      attr_reader :db_config

      def initialize(cfg_file = nil, env = :production)
        # @cfg_file = cfg_file
        # @env = env
        # noinspection RubyResolve
        @db_config = YAML.load(ERB.new(File.read(cfg_file)).result)[env.to_s]

      end

      def connect
        return if ActiveRecord::Base.connected?
        ActiveRecord::Base.establish_connection @db_config

      end

    end
  end
end
