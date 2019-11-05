# frozen_string_literal: true

require_relative 'converter'

module Teneo
  module Ingester
    module Converters
      module Base

        class Selecter < Teneo::Ingester::Converters::Base::Converter

          taskgroup :selecter
          recursive false
          item_types Teneo::Ingester::ItemGroup

          protected

          def process(item, *_args, **options)
            items = options[:source_items]
            select_items(items, item)
            item
          end

          def select_items(_source_items, _target_group)
          end

        end
      end
    end
  end
end
