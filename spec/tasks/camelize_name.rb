# frozen_string_literal: true

require 'backports/rails/string'

require 'libis/workflow'
require 'teneo/ingester/tasks/base/task'

class CamelizeName < Teneo::Ingester::Tasks::Base::Task

  recursive true
  item_types  Teneo::Ingester::FileItem, Teneo::Ingester::DirItem

  def process(item, *_args)
    item.name = item.name.camelize
    item.save!
    item
  end

end
