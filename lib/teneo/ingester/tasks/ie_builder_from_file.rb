# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class IeBuilderFromFile < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_ingest

        recursive true
        item_types Teneo::Ingester::FileItem

        protected

        def pre_process(item, *_args)
          if check_item_type(item, Teneo::Ingester::IntellectualEntity, raise_on_error: false)
            stop_recursion
            return false
          end
          super
        end

        def process(item, *_args)
          ie = create_ie(item)
          ie.save!
          item = ie.move_item(item)
          debug 'File item %s moved to IE item %s', item, item.name, ie.name
          item
        end

        def create_ie(item)
          # Create an the IE for this item
          debug "Creating new IE item for item #{item.name}", item
          ie = Teneo::Ingester::IntellectualEntity.new
          ie.name = item.name
          ie.label = item.label

          # Add IE to item's parent
          item.parent.add_item(ie)

          # returns the newly created IE
          ie
        end

      end

    end
  end
end
