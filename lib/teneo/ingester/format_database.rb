# frozen_string_literal: true
require "libis-format"
require "singleton"

module Teneo
  module Ingester
    class FormatDatabase
      include Singleton

      def self.register
        Libis::Format::Library.implementation = self.instance
      end

      def query(key, value)
        case key.to_s.downcase.to_sym
        when :name
          Teneo::DataModel::Format.where(name: value.to_s.upcase)
        when :category
          Teneo::DataModel::Format.where(category: value.to_s.upcase)
        when :puid
          Teneo::DataModel::Format.where.any(puids: value)
        when :mimetype
          Teneo::DataModel::Format.where.any(mimetypes: value)
        when :extension
          Teneo::DataModel::Format.where.any(extensions: value)
        else
          nil
        end
      rescue ActiveRecord::ActiveRecordError
        nil
      end
    end
  end
end
