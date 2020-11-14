# frozen_string_literal: true

require_relative 'task'

module Teneo
  module Ingester
    module Converters
      module Base
        class Assembler < Teneo::Ingester::Converters::Base::Task
          taskgroup :assembler
          recursive false
          item_types Teneo::DataModel::ItemGroup

          protected

          def process(item, *_args)
            unless (format = parameter(:format))
              error 'Converter target format not specified', item
              raise Teneo::WorkflowError, 'Converter target format not specified'
            end
            target = target_name(item, format)
            source_items = item.files.find_each(batch_size: 100).to_a
            source_files = source_items.map(&:fullpath)
            Libis::Format::Converter::Base.using_temp(target) do |target_temp|
              assemble(source_files, target_temp, format)
            end
            new_item = Teneo::DataModel::FileItem.new
            new_item.filename = target
            new_item.own_file(true)
            item << new_item
            new_item.save!
            source_items.each { |item| item.move_logs(new_item) }
            source_items.map(&:destroy!)
            identify(new_item)
            new_item
          end

          def target_name(item, format)
            ie = item.find_parent(Teneo::DataModel::IntellectualEntity)
            filename = [ie.name, short_name, extname(format)].join('.')
            File.join(item.work_dir, filename)
          end
        end
      end
    end
  end
end
