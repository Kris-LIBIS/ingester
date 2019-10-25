# encoding: utf-8

module Teneo
  module Ingester

    class Representation < WorkItem

      # @return [Teneo::DataModel::RepresentationInfo]
      def representation_info
        Teneo::DataModel::RepresentationInfo.find_by(options[:representation_info_id])
      end

      # @param [Teneo::DataModel::RepresentationInfo] value
      def representation_info=(value)
        raise Teneo::Ingester::WorkflowAbort, 'Invalid RepresentationInfo object' unless value.nil? ||
            value.is_a?(Teneo::DataModel::RepresentationInfo)
        options[:representation_info_id] = value&.id
      end

      def files
        items.where(type: Teneo::Ingester::FileItem.to_s)
      end

      def divisions
        items.where(type: Teneo::Ingester::ItemGroup.to_s)
      end

      def all_files
        Teneo::DataModel::Item.where(parent_id: self.class.div_ids(self))
      end

      # noinspection RubyResolve
      def to_hash
        super.merge(self.representation_info.to_hash)
      end

      def self.div_ids(instance)
        where(type: 'Teneo::Ingester::ItemGroup')
            .where("#{table_name}.id IN (#{tree_sql(instance)}}")
            .order("#{table_name}.id")
            .pluck(:id)
      end

    end

  end
end
