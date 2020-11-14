# frozen_string_literal: true

require_relative 'base'
require_relative 'serializers/symbol_serializer'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class StatusLog < Base
    include Teneo::Workflow::StatusLog

    self.table_name = 'status_logs'

    default_scope { order(created_at: :asc) }

    belongs_to :item
    belongs_to :run

    serialize :status, Serializers::SymbolSerializer

    def self.create_status(status:, task:, item: nil, progress: nil, max: nil)
      run, task, item = sanitize(task: task, item: item)
      values = { status: status, run: run, task: task, item: item, progress: progress, max: max }.compact
      create!(values)
    end

    def self.find_last(run: nil, task: nil, item: nil)
      if task.is_a?(String)
        _run, task, item = sanitize(run: run, task: task, item: item)
        Teneo::DataModel::StatusLog.where(task: task, item_id: item&.id).last
      else
        run, task, item = sanitize(run: run, task: task, item: item)
        Teneo::DataModel::StatusLog.where(run_id: run&.id, task: task, item_id: item&.id).last
      end
    end

    def self.find_all(run: nil, task: nil, item: nil)
      run, task, item = sanitize(run: run, task: task, item: item)
      query = { run: run, task: task }.compact
      query[:item] = item
      self.where(query).order(created_at: :asc)
    end

    def update_status(values = {})
      values = values.compact.slice(:status, :progress, :max)
      update(values)
      save!
    end

    # noinspection RubyResolve
    def pretty
      {status: status, run: run.id, task: task, item: item&.namepath, progress: progress, max: max,
       created: created_at.strftime('%Y-%m-%d %H:%M:%S.%N'), updated: updated_at.strftime('%Y-%m-%d %H:%M:%S.%N') }
    end
  end
end
