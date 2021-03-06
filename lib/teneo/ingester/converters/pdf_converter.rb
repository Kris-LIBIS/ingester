# frozen_string_literal: true

require 'libis/format/converter/pdf_converter'

require_relative 'base/converter'

module Teneo
  module Ingester
    module Converters

      class PdfConverter < Teneo::Ingester::Converters::Base::Converter

        description ''

        parameter title: nil, description: 'PDF internal metadata title field'
        parameter author: nil, description: 'PDF internal metadata author field'
        parameter creator: nil, description: 'PDF internal metadata creator field'
        parameter keywords: nil, description: 'PDF internal metadata keywords field'
        parameter subject: nil, description: 'PDF internal metadata subject field'

        parameter ranges: nil, description: 'Select a partial list of pages',
                  help: <<~STR
                    The general syntax is:
                    [!][o][odd][e][even]start-end

                    You can have multiple ranges separated by commas ','. The '!' modifier removes the range from what is already
                    selected. The range changes are incremental, that is, numbers are added or deleted as the range appears. The
                    start or the end, but not both, can be omitted.

                    See also the documentation for com.itextpdf.text.pdf.SequenceList
        STR

        converter_class Libis::Format::Converter::PdfConverter

        protected

        def convert(source_path, target_path, format)
          # noinspection RubyNilAnalysis
          converter = self.class.converter_class.new
          options = {
              title: parameter(:title),
              author: parameter(:author),
              creator: parameter(:creator),
              keywords: parameter(:keywords),
              subject: parameter(:subject),
              ranges: parameter(:ranges),
          }.compact
          converter.convert(source_path, target_path, format, options: options)
        end

      end
    end
  end
end
