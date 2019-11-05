# frozen_string_literal: true

require 'libis/format/converter/image_assembler'

require_relative 'base/assembler'

module Teneo
  module Ingester
    module Converters

      class ImageAssembler < Teneo::Ingester::Converters::Base::Assembler

        description ''

        parameter quiet: false, description: 'no output'

        converter_class Libis::Format::Converter::ImageAssembler

        protected

        def assemble(source_paths, target_path, format)
          # noinspection RubyNilAnalysis
          assembler = self.class.converter_class.new
          assembler.quiet !!parameter(:quiet)
          assembler.convert(source_paths, target_path, format)
        end

      end
    end
  end
end
