# frozen_string_literal: true

require 'teneo/data_model/item'

module Teneo::DataModel

  class Item

    include Libis::Workflow::WorkItem

    def <<(item)
      item.parent = self
    end

    def item_list
      items.to_a
    end

  end
end
