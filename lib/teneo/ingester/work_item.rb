# frozen_string_literal: true

require_relative 'workflow/item_injector'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class WorkItem < Teneo::DataModel::Item

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
