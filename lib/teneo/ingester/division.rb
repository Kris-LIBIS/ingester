# frozen_string_literal: true

module Teneo
  module Ingester
    class Division

      include Libis::Workflow::FileItem

      def filename=(dir)
        raise "'#{dir}' is not a directory" unless File.directory? dir
        self.name = File.basename(dir)
        super
      end

      def divisions
        items.where(type: 'Teneo::Ingester::Division')
      end

      def files
        items.where(type: 'Teneo::Ingester::FileItem')
      end

      def all_divs
        self.class.div_tree(self)
      end

      def file_divs
        self.class.file_tree(self)
      end

      def self.div_tree(instance)
        where(type: 'Teneo::Ingester::Division')
            .where("#{table_name}.id IN (#{tree_sql(instance)}}")
            .order("#{table_name}.id")
      end

      def self.file_tree(instance)
        where(type: 'Teneo::Ingester::FileItem').where(tree_sql(instance)).order("#{table_name}.id")
      end

    end
  end
end
