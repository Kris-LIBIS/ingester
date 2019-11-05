# frozen_string_literal: true

require 'libis/format/converter/pdf_assembler'

require_relative 'base/assembler'

module Teneo
  module Ingester
    module Converters

      class PdfAssembler < Teneo::Ingester::Converters::Base::Assembler

        description ''

        converter_class Libis::Format::Converter::PdfAssembler

        protected

        def assemble(source_paths, target_path, format)
          # noinspection RubyNilAnalysis
          assembler = self.class.converter_class.new
          assembler.convert(source_paths, target_path, format)
        end

      end
    end
  end
end
