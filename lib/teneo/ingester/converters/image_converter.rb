# frozen_string_literal: true

require 'libis/format/converter/image_converter'

require_relative 'base/converter'

module Teneo
  module Ingester
    module Converters

      class ImageConverter < Teneo::Ingester::Converters::Base::Converter

        description ''

        parameter quiet: false, description: 'no output'
        parameter page: nil, datatype: :int, description: 'page to use for multipage source formats'
        parameter scale: nil, datatype: :int, description: 'image scale for the target image'
        parameter resize: nil, datatype: :string, description: 'change the target image geometry'
        parameter quality: nil, datatype: :int, description: 'target image quality, 0-100'
        parameter dpi: nil, datatype: :int, description: 'DPI value for target image'
        parameter resample: nil, datatype: :int, description: 'resample target image'
        parameter flatten: false, description: 'Flattens the pages in the source image before conversion'
        parameter colorspace: 'sRGB', description: 'Sets the colorspace for the target image'
        parameter delete_date: false, description: 'Prevent the converter of updating the image dates in the target'
        parameter profile: nil, datatype: :string, description: 'Select a ICC profile to include in the target'

        converter_class Libis::Format::Converter::ImageConverter

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
          options = {
              scale: parameter(:scale),
              resize: parameter(:resize),
              quality: parameter(:quality),
              dpi: parameter(:dpi),
              resample: parameter(:resample),
              flatten: parameter(:flatten),
              colorspace: parameter(:colorspace),
              delete_date: parameter(:delete_date),
          }.compact
          converter.quiet !!parameter(:quiet)
          converter.page parameter(:page).to_i if parameter(:page)
          converter.profile parameter(:profile) if parameter(:profile)
          converter.convert(source_path, target_path, format, options)
        end

      end
    end
  end
end
