# frozen_string_literal: true

require_relative 'base_sorted'
require_relative 'serializers/hash_serializer'
require_relative 'storage_resolver'

require 'active_support/core_ext/hash/indifferent_access'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class Item < BaseSorted
    include Teneo::Workflow::WorkItem

    self.table_name = 'items'
    ranks :position, class_name: self.name, with_same: [:parent_id, :parent_type]

    has_many :status_logs, inverse_of: :item, dependent: :destroy
    has_many :message_logs, inverse_of: :item, dependent: :destroy
    has_one :metadata_record, inverse_of: :item, dependent: :destroy

    belongs_to :parent, polymorphic: true
    has_many :items, -> { rank(:position) }, as: :parent, class_name: 'Teneo::DataModel::Item', dependent: :destroy

    serialize :options, Serializers::HashSerializer
    serialize :properties, Serializers::HashSerializer

    include StorageResolver

    def organization
      parent&.organization
    end

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

    def move_logs(new_item = nil)
      new_item ||= item.parent
      items.each { |item| item.move_logs(new_item) }
      message_logs.each { |entry| entry.item = new_item; entry.save! }
      status_logs.each { |entry| entry.item = new_item; entry.save! }
    end

    def label
      super || name
    end

    def filelist
      []
    end

    def template_vars
      options.to_hash.merge(properties.to_hash).merge(
        id: id,
        name: name,
        label: label,
      )
    end

    def interpolate(str, **vars)
      sprintf(str, template_vars.merge(vars))
    end

    def self.tree_sql(instance)
      <<~SQL
        WITH RECURSIVE tree(id, path) AS (
            SELECT *, ARRAY[id]
            FROM #{table_name}
            WHERE parent_id = #{instance.id}
          UNION ALL
            SELECT #{table_name}.*, path || #{table_name}.id
            FROM tree
            JOIN #{table_name} ON #{table_name}.parent_id = tree.id
            WHERE NOT #{table_name}.id = ANY(path)
        )
        SELECT * FROM tree ORDER BY path
      SQL
    end

    def find_parent(klass)
      item = self
      until item.is_a?(klass)
        return nil unless item
        item = item.parent
      end
      item
    end
  end
end
