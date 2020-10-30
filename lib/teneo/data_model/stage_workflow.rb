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

    def tasks_info(param_list)
      tasks.each_with_object([]) do |task, result|
        params = param_list.each_with_object({}) do |(key, value), hash|
          param_host, param_name = Parameter.reference_split(key)
          hash[param_name] = value if param_host == task.name
        end
        result << {
            class: task.class_name,
            name: task.name,
            description: task.description,
            parameters: task.parameter_values(true, false).merge(params)
        }
      end
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
