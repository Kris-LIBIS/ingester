# frozen_string_literal: true

require 'libis/exceptions'
require 'libis/workflow'

class FinalTask < Teneo::Ingester::Task

  def process(item)
    return unless item.is_a? Teneo::Ingester::FileItem

    info "Final processing of #{item.name}"
  end

end
