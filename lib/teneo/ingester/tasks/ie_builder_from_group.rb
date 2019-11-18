# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class IeBuilderFromGroup < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_ingest

        description 'Generate IEs from item groups'

        help_text <<~STR
          Any item groups found will be converted into IntellectualEntity items. Item groups that are themselves
          contained in an IntellectualEntity will be left alone.
        STR

        recursive true
        item_types Teneo::Ingester::ItemGroup

        protected

        def pre_process(item, *_args)
          if check_item_type(item, Teneo::Ingester::IntellectualEntity, raise_on_error: false)
            stop_recursion
            return false
          end
          super
        end

        def process(item, *_args)
          debug 'Converting ItemGroup into an IE', item
          # ItemGroup objects are replaced with the IE
          item.becomes!(Teneo::Ingester::IntellectualEntity)
          stop_recursion
          item
        end

      end

    end
  end
end
