# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection ALL
  class StageWorkflow < Base
    self.table_name = 'stage_workflows'

    STAGE_LIST = Teneo::DataModel::Task::STAGE_LIST

    has_many :stage_tasks, -> { rank(:position) }, inverse_of: :stage_workflow, dependent: :destroy
    has_many :tasks, through: :stage_tasks

    has_many :ingest_stages, inverse_of: :stage_workfow, dependent: :nullify
    has_many :ingest_workflows, through: :ingest_stages

    validates :name, presence: true
    validates :stage, presence: true, inclusion: { in: STAGE_LIST }

    include WithParameters

    def parameter_children
      tasks
    end

    def self.from_hash(hash, id_tags = [:name])
      params = hash.delete(:parameters) || {}
      tasks = hash.delete(:tasks) || []

      super(hash, id_tags).tap do |item|
        old = item.stage_tasks.map(&:id)
        tasks.each_with_index do |task, i|
          params.merge!(params_from_values(task[:task], task.delete(:values)))
          task[:stage_workflow_id] = item.id
          task[:position] = i + 1
          item.stage_tasks << Teneo::DataModel::StageTask.from_hash(task)
        end
        (old - item.stage_tasks.map(&:id)).each { |id| item.stage_tasks.find(id)&.destroy! }
      end.params_from_hash(params)
    end

  end

end
