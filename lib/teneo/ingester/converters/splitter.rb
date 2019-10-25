# frozen_string_literal: true

module Teneo
  module Ingester

    class Splitter < Teneo::Ingester::Converter

      taskgroup :splitter

      description ''

      help <<-STR.align_left
        help text
      STR

      def initialize(cfg = {})
        super
      end

      protected

      def process(item)
      end

    end
  end
end
