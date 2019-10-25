# frozen_string_literal: true

module Teneo
  module Ingester

    class Assembler < Teneo::Ingester::Converter

      taskgroup :assembler

      description ''

      help <<-STR.align_left
        help text
      STR

      protected

      def process_item(item, *args)
      end

    end
  end
end
