# frozen_string_literal: true
require 'libis/workflow/task'

module Teneo
  module Ingester
    class Task < ::Libis::Workflow::Task

      parameter item_types: nil, datatype: Array,
                description: 'Item types to process.'

      def self.taskgroup(name = nil)
        @taskgroup = name if name
        @taskgroup || superclass.group rescue nil
      end

      def self.description(text = nil)
        @description = text if text
        @description
      end

      def self.help(text = nil)
        @helptext = text if text
        @helptext
      end

      def allowed_item_types
        [Teneo::Ingester::Package, Teneo::Ingester::WorkItem]
      end

      def execute(item, *args)
        item = super *args
        item&.reload
        item
      end

      protected

      def pre_process(item, *_args)
        return false unless parameter(:item_types).blank? ||
            parameter(:item_types).any? { |klass| item.is_a?(klass.to_s.constantize) }
        item.reload
        super
      end

      def post_process(item, *_args)
        item.save!
        item.reload
      end

    end
  end
end