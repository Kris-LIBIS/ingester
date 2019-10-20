# frozen_string_literal: true

require 'libis/exceptions'
require 'libis/workflow'

class ProcessingTask < Teneo::Ingester::Task

  parameter config: 'success', constraint: %w[success async_halt fail error abort],
            description: 'determines the outcome of the processing'

  def process(item)
    return item unless item.is_a? Teneo::Ingester::FileItem

    case parameter(:config).downcase.to_sym
    when :success
      info 'Task success', item
    when :async_halt
      set_item_status(status: :async_halt, item: item)
      error 'Task failed with async_halt status', item
    when :fail
      set_item_status(status: :failed, item: item)
      error 'Task failed with failed status', item
    when :error
      msg = 'Task failed with WorkflowError exception'
      error msg, item
      raise Teneo::Ingester::WorkflowError, msg
    when :abort
      msg = 'Task failed with WorkflowAbort exception'
      error msg, item
      raise Teneo::Ingester::WorkflowAbort, msg
    else
      info 'Task success', item
    end

    item
  end

end
