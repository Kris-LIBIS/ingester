# frozen_string_literal: true
require 'ranked-model'
require 'active_support/concern'
require_relative 'base'

module Teneo
  module DataModel
    class BaseSorted < Base
      include RankedModel

      self.abstract_class = true

      def insert_at(pos)
        update position_position: pos
      end

      protected

      def volatile_attributes
        super + ['position']
      end

    end

  end
end