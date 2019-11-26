# frozen_string_literal: true

require 'teneo/data_model/status_log'

module Teneo::DataModel

  class StatusLog

    include Libis::Workflow::StatusLog

    def self.create_status(status:, task:, item: nil, progress: nil, max: nil)
      run, task, item = sanitize(task: task, item: item)
      values = {status: status, run: run, task: task, item: item, progress: progress, max: max}.compact
      # print_values = {}
      # print_values[:run] = run.id if run
      # print_values[:item] = item.id if item
      # puts "StatusLog create: #{values.merge(print_values)}"
      create!(values)
    end

    def self.find_last(task:, item: nil)
      if task.is_a?(String)
        run, task, item = sanitize(task: task, item: item)
        Teneo::DataModel::StatusLog.where(task: task, item_id: item&.id).last
      else
        run, task, item = sanitize(task: task, item: item)
        Teneo::DataModel::StatusLog.where(run_id: run&.id, task: task, item_id: item&.id).last
      end
    end

    def self.find_all(run: nil, task: nil, item: nil)
      run, task, item = sanitize(run: run, task: task, item: item)
      query = {run: run, task: task}.compact
      query[:item] = item
      self.where(query).order(created_at: :asc)
    end

    def update_status(values = {})
      values = values.compact.slice(:status, :progress, :max)
      # print_values = {}
      # print_values[:run] = run.id if run
      # print_values[:item] = item.id if item
      # puts "StatusLog update: #{values.merge(print_values)}"
      update(values)
      save!
    end

    # noinspection RubyResolve
    def pretty
      { status: status, run: run.id, task: task, item: item&.namepath, progress: progress, max: max,
        created: created_at.strftime('%Y-%m-%d %H:%M:%S.%N'), updated: updated_at.strftime('%Y-%m-%d %H:%M:%S.%N') }
    end

  end

end
