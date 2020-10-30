# frozen_string_literal: true

require 'json'
require 'symbolized'

module Teneo
  module DataModel
    module Serializers

      class HashSerializer
        def self.dump(hash)
          return hash if hash.is_a?(String)
          hash.to_json
        end

        def self.load(hash)
          return nil if hash.nil? or hash.empty?
          hash = JSON.parse(hash) if hash.is_a?(String)
          (hash || {}).to_symbolized_hash
        end
      end

    end
  end
end
