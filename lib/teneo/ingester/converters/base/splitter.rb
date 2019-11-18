# frozen_string_literal: true

require_relative 'task'

module Teneo
  module Ingester
    module Converters
      module Base

        class Splitter < Teneo::Ingester::Converters::Base::Task

          taskgroup :splitter
          recursive true
          item_types Teneo::Ingester::FileItem

          def pre_process(item, *_args)
            super && check_format(item)
          end

          def process(item, *_args, **_options)
            items = split(item, item)
            items
          end

        end
      end
    end
  end
end
