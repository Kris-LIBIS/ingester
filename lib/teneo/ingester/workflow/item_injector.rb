# frozen_string_literal: true

require 'teneo/data_model/item'

module Teneo::DataModel

  class Item

    include Libis::Workflow::WorkItem

    def <<(item)
      item.parent = self
      item.insert_at :last
    end

    alias add_item <<

    def copy_item(item, recursive: true)
      new_item = item.dup
      add_item(new_item)
      yield new_item, item if block_given?
      new_item.save!
      if recursive
        item.items.find_each(batch_size: 100) { |i| new_item.copy_item(i) }
        new_item.reload
      end
      new_item
    end

    def move_item(item)
      old_parent = item.parent
      add_item(item)
      yield item, old_parent, self if block_given?
      item
    end

    def item_list
      items.to_a
    end

    def work_dir
      parent.work_dir
    end

  end
end
