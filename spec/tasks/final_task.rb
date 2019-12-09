# frozen_string_literal: true

require 'libis/exceptions'
require 'libis/workflow'
require 'teneo/ingester/tasks/base/task'

class FinalTask < Teneo::Ingester::Tasks::Base::Task

  recursive true
  item_types Teneo::Ingester::FileItem

  parameter run_always: false

  def run_always
    parameter(:run_always)
  end

  def process(item, *_args)
    return unless item.is_a? Teneo::Ingester::FileItem

    info "Final processing of #{item.name}"
  end

end
