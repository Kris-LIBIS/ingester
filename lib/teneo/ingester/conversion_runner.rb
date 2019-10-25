# frozen_string_literal: true

module Teneo
  module Ingester

    class ConversionRunner < Libis::Workflow::TaskGroup

      parameter item_types: [Teneo::Ingester::Representation], datatype: Array,
                description: 'Item types to process.'

      attr_accessor :action

      def allowed_item_types
        [Teneo::Ingester::Representation]
      end

      def execute(item, *_args)
        @action = :start
        item = super
        item.reload
        item
      end

      def configure_tasks(tasks, opts = {})
        tasks.each do |task|
          task_obj = task[:class].constantize.new(task)
          task_obj.configure(task[:parameters])
          self << task_obj
        end
      end

      protected

      def pre_process(item, *_args)
        return false unless item.is_a?(Teneo::Ingester::Representation)
        super
      end

      def post_process(item, *_args)
        item.save!
        item.reload
      end

      def process(item, *args)

      end

    end
  end
end
