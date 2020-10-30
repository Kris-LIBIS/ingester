# frozen_string_literal: true

require 'json'

module Teneo
  module DataModel
    module Serializers

      class SymbolSerializer
        def self.dump(sym)
          sym ? sym.to_s : nil
        end

        def self.load(text)
          text ? text.to_sym : nil
        end
      end

    end
  end
end
