# frozen_string_literal: true

require_relative 'converter'

module Teneo
  module Ingester
    module Converters
      module Base

        class Assembler < Teneo::Ingester::Converters::Base::Converter

          taskgroup :assembler
          recursive false
          item_types Teneo::Ingester::ItemGroup

          protected

          def process(item, *_args)
            unless (format = parameter(:format))
              error 'Converter target format not specified', item
              raise WorkflowError, 'Converter target format not specified'
            end
            target = target_name(item, format)
            source_items = item.files
            source_files = source_items.find_each(batch_size: 100).map(&:fullpath)
            Libis::Format::Converter::Base.using_temp(target) do |target_temp|
              assemble(source_files, target_temp, format)
            end
            new_item = Teneo::Ingester::FileItem.new
            new_item.filename = target
            new_item.own_file(true)
            item << new_item
            new_item.save!
            source_items.map(&:destroy!)
            new_item
          end

        end
      end
    end
  end
end
