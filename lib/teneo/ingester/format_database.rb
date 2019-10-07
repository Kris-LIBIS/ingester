# frozen_string_literal: true
require 'libis-format'
require 'teneo-data_model'

require 'singleton'

module Teneo
  module Ingester

    class FormatDatabase
      include Singleton

      def self.register
        Libis::Format::Library.implementation = Teneo::Ingester::FormatDatabase.instance
      end

      def get_info(format)
        get_info_by :format, format
      end

      def get_info_by(key, value)
        transform_hash query(key, value)&.first
      end

      def get_infos_by(key, value)
        query(key, value)&.map { |h| transform_hash(h) } || []
      end

      protected

      def query(key, value)
        key = key.to_sym
        case key
        when :format
          Teneo::DataModel::Format.where(name: value)
        when :category
          Teneo::DataModel::Format.where(category: value)
        when :puid
          Teneo::DataModel::Format.where.any(puids: value)
        when :mime_type
          Teneo::DataModel::Format.where.any(mime_types: value)
        when :extension
          Teneo::DataModel::Format.where.any(extensions: value)
        else
          nil
        end
      rescue ActiveRecord::ActiveRecordError
        nil
      end


      def transform_hash(hash)
        return hash unless hash.is_a?(Hash)
        hash.transform_keys do |k|
          k.to_s == 'name' ? :format : k.to_s.upcase.to_sym
        end
      end

    end

  end
end

