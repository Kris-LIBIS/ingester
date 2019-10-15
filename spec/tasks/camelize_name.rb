# frozen_string_literal: true

require 'backports/rails/string'

require 'libis/workflow'

class CamelizeName < Teneo::Ingester::Task

  def process(item)
    return unless item.is_a?(Teneo::Ingester::FileItem) || item.is_a?(Teneo::Ingester::DirItem)

    item.properties[:name] = item.name.camelize
  end

end
