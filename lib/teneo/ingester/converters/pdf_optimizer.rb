# frozen_string_literal: true

require 'libis/format/converter/pdf_optimizer'

require_relative 'base/converter'

module Teneo
  module Ingester
    module Converters

      class PdfOptimizer < Teneo::Ingester::Converters::Base::Converter

        description ''

        parameter quality: 1, datatype: 'int', constraint: [1, 2, 3, 4], description: 'Graphics quality level',
                  help: <<~STR
                    This reduces the graphics quality to a level in order to limit file size. This option relies on the
                    presence of ghostscript and takes one argument: the quality level. It should be one of:

                    - 0 : lowest quality (Acrobat Distiller 'Screen Optimized' equivalent)
                    - 1 : medium quality (Acrobat Distiller 'eBook' equivalent)
                    - 2 : good quality
                    - 3 : high quality (Acrobat Distiller 'Print Optimized' equivalent)
                    - 4 : highest quality (Acrobat Distiller 'Prepress Optimized' equivalent)

                    Note that the optimization is intended to be used with PDF's containing high-resolution images.
        STR

        converter_class Libis::Format::Converter::PdfOptimizer

        protected

        def pre_process(item, *_args)
          unless self.class.input_formats.include? item.properties[:format_type].to_s
            warn "File format %s is not supported", item, item.properties[:format_type]
            return false
          end
          super
        end

        def convert(source_path, target_path, format)
          # noinspection RubyNilAnalysis
          converter = self.class.converter_class.new
          converter.quality parameter(:quality).to_i
          converter.convert(source_path, target_path, format)
        end

      end
    end
  end
end
