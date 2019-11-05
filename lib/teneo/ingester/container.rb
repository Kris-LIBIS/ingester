# frozen_string_literal: true

module Teneo
  module Ingester
    module Container

      def groups
        items.where(type: Teneo::Ingester::ItemGroup.name)
      end

      def dirs
        items.where(type: Teneo::Ingester::DirItem.name)
      end

      def files
        items.where(type: Teneo::Ingester::FileItem.name)
      end

      def all_groups
        self.class.group_tree(self)
      end

      def all_dirs
        self.class.dir_tree(self)
      end

      def all_files
        self.class.file_tree(self)
      end

      def self.group_tree(instance)
        where(type: Teneo::Ingester::ItemGroup.name)
            .where("#{table_name}.id IN (#{tree_sql(instance)}}")
            .order("#{table_name}.id")
      end

      def self.dir_tree(instance)
        where(type: Teneo::Ingester::DirItem.name)
            .where("#{table_name}.id IN (#{tree_sql(instance)}}")
            .order("#{table_name}.id")
      end

      def self.file_tree(instance)
        where(type: Teneo::Ingester::FileItem.name).where(tree_sql(instance)).order("#{table_name}.id")
      end

    end
  end
end
