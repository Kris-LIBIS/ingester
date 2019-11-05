# frozen_string_literal: true

require_relative 'converter'

module Teneo
  module Ingester
    module Converters
      module Base

        class Splitter < Teneo::Ingester::Converters::Base::Converter

          taskgroup :splitter
          recursive true
          item_types Teneo::Ingester::FileItem

        end
      end
    end
  end
end
