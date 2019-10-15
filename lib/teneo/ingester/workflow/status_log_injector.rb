# frozen_string_literal: true

require 'teneo/data_model/status_log'

module Teneo::DataModel

  class StatusLog

    include Libis::Workflow::StatusLog

    def self.create_status(status:, task:, item: nil, max: nil)
      run, task, item = sanitize(task: task, item: item)
      create(status: status, run: run, task: task, item: item, max: max)
    end

    def self.find_last(task:, item: nil)
      run, task, item = sanitize(task: task, item: item)
      self.where(run: run, task: task, item: item).order_by(updated_at: :desc).first
    end

    def self.find_all(run: nil, task: nil, item: nil)
      run, task, item = sanitize(run: run, task: task, item: item)
      query = {run: run, task: task}.compact
      query[:item] = item
      self.where(query).order_by(created_at: :asc)
    end

    def update_status(values = {})
      update_attributes(values.slice(:status, :progress, :max))
      save
    end

    # noinspection RubyResolve
    def pretty
      { status: status, run: run.name, task: task, item: item&.namepath, progress: progress, max: max,
        created: created_at.strftime('%Y-%m-%d %H:%M:%S.%N'), updated: updated_at.strftime('%Y-%m-%d %H:%M:%S.%N') }
    end

  end

end
