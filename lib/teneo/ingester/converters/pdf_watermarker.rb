# frozen_string_literal: true

require 'libis/format/converter/pdf_watermarker'

require_relative 'base/converter'

module Teneo
  module Ingester
    module Converters

      class PdfWatermarker < Teneo::Ingester::Converters::Base::Converter

        description ''

        parameter file: nil, description: 'Image file for the watermark'
        parameter text: nil, description: 'Watermark text'
        parameter rotation: nil, datatype: 'int', description: 'Counter-clockwise rotation in degrees'
        parameter size: nil, datatype: 'int', description: 'Font size in points'
        parameter opacity: nil, datatype: 'float', description: 'Opacity expressed as fraction (0.0 -> 1.0)'
        parameter gap_size: nil, datatype: 'int', description: 'The gap between watermark repeats in number of pixels.'
        parameter gap_ratio: nil, datatype: 'float',
                  description: 'The gap between watermark repeats in percentage of the watermark size'

        converter_class Libis::Format::Converter::PdfWatermarker

        protected

        def convert(source_path, target_path, format)
          # noinspection RubyNilAnalysis
          converter = self.class.converter_class.new
          options = {
              file: parameter(:file),
              text: parameter(:text),
              rotation: parameter(:rotation),
              size: parameter(:size),
              opacity: parameter(:opacity),
              gap_size: parameter(:gap_size),
              gap_ratio: parameter(:gap_ratio),
          }.compact
          converter.convert(source_path, target_path, format, options: options)
        end

      end
    end
  end
end
