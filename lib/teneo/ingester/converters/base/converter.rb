# frozen_string_literal: true

require 'libis-format'

require_relative 'task'

module Teneo
  module Ingester
    module Converters
      module Base

        class Converter < Teneo::Ingester::Converters::Base::Task

          taskgroup :converter
          recursive true
          item_types Teneo::Ingester::FileItem

          protected

          def pre_process(item, *_args)
            super && check_format(item)
          end

          def process(item, *_args)
            unless (format = parameter(:format))
              error 'Converter target format not specified', item
              raise WorkflowError, 'Converter target format not specified'
            end
            target = target_name(item, format)
            FileUtils.mkpath(File.dirname(target))
            Libis::Format::Converter::Base.using_temp(target) do |target_temp|
              convert(item.fullpath, target_temp, format)
              item.delete_file
              target_temp
            end
            item.filename = target
            item.own_file(true)
            identify(item)
            item
          end

        end
      end
    end
  end
end
