# frozen_string_literal: true

require 'json'

module Teneo
  module DataModel
    module Serializers

      class ArraySerializer
        def self.dump(array)
          return array if array.is_a?(String)
          array = [array] unless array.is_a?(Array)
          array.to_json
        end

        def self.load(array)
          return nil if array.nil? or array.empty?
          array = JSON.parse(array) if array.is_a?(String)
          array = [] unless array.is_a?(Array)
          array
        end
      end

    end
  end
end
