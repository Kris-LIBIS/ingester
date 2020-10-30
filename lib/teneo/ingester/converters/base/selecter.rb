# frozen_string_literal: true

require_relative "task"

module Teneo
  module Ingester
    module Converters
      module Base
        class Selecter < Teneo::Ingester::Converters::Base::Task
          taskgroup :selecter
          recursive false
          item_types Teneo::DataModel::ItemGroup

          protected

          def process(item, *_args, **options)
            items = options[:source_items]
            select_items(items, item)
            item
          end
        end
      end
    end
  end
end
