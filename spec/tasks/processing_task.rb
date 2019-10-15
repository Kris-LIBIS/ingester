# frozen_string_literal: true

require 'libis/exceptions'
require 'libis/workflow'

class ProcessingTask < Teneo::Ingester::Task

  parameter config: 'success', constraint: %w[success async_halt fail error abort],
            description: 'determines the outcome of the processing'

  def process(item)
    return unless item.is_a? Teneo::Ingester::FileItem

    case parameter(:config).downcase.to_sym
    when :success
      info 'Task success', item
    when :async_halt
      set_status(status: :async_halt, item: item)
      error 'Task failed with async_halt status', item
    when :fail
      set_status(status: :failed, item: item)
      error 'Task failed with failed status', item
    when :error
      raise Teneo::Ingester::WorkflowError, 'Task failed with WorkflowError exception'
    when :abort
      raise Teneo::Ingester::WorkflowAbort, 'Task failed with WorkflowAbort exception'
    else
      info 'Task success', item
    end
  end

end
