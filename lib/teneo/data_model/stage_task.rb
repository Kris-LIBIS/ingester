# frozen_string_literal: true
require 'active_support/core_ext/object/with_options'

require_relative 'base_sorted'

module Teneo
  module DataModel
    # noinspection RailsParamDefResolve
    class StageTask < BaseSorted
      self.table_name = 'stage_tasks'
      ranks :position, with_same: :stage_workflow_id

      belongs_to :stage_workflow
      belongs_to :task

      def name
        task.name
      end

      def self.from_hash(hash, id_tags = [:stage_workflow_id, :position])
        super(hash, id_tags) do |item, h|
          if (task = h.delete(:task))
            item.task = record_finder Teneo::DataModel::Task, name: task
          end
        end
      end

    end
  end
end
