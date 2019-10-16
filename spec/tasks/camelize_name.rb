# frozen_string_literal: true

require 'backports/rails/string'

require 'libis/workflow'

class CamelizeName < Teneo::Ingester::Task

  def process(item)
    return unless item.is_a?(Libis::Workflow::FileItem)

    item.name = item.name.camelize
    item.save
    item
  end

end
