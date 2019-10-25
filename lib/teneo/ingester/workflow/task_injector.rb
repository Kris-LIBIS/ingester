# frozen_string_literal: true

require 'libis/workflow/task'

module Libis::Workflow

  class Task

    def add_log_entry(severity, item, msg, *args)
      message = (msg % args rescue "#{msg}#{args.empty? ? '' : " - #{args}"}")
      message, *stack_trace = message.split("\n")
      Teneo::DataModel::MessageLog.create(
          severity: severity,
          item: item.is_a?(Teneo::Ingester::WorkItem) ? item : nil,
          run: self.run,
          task: namepath,
          message: message,
          data: {
              run_name: self.run&.name,
              item_name: item&.name,
              item_type: item&.class&.name,
              stack_trace: stack_trace.empty? ? nil : stack_trace,
          }.compact
      )
    end

    protected

    def pre_process(item, *_args)
      item.reload
    end

    def post_process(item, *_args)
      item.save!
      item.reload
    end

  end
end
