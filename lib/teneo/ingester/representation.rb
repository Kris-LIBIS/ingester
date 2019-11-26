# encoding: utf-8

module Teneo
  module Ingester

    class Representation < WorkItem

      include Teneo::Ingester::Container

      before_destroy :delete_work_dir

      def delete_work_dir
        #noinspection RubyArgCount
        FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
      end

      def work_dir
        File.join(parent.work_dir, name)
      end

      # @param [Teneo::DataModel::AccessRight] value
      def access_right=(value)
        raise Teneo::Ingester::WorkflowAbort, 'Invalid AccessRight object' unless value.nil? ||
            value.is_a?(Teneo::DataModel::AccessRight)
        options[:access_right_id] = value&.id
      end

      # @return [Teneo::DataModel::AccessRight]
      def access_right
        return nil unless options[:access_right_id]
        Teneo::DataModel::AccessRight.find_by(id: options[:access_right_id])
      end

      # @param [Teneo::DataModel::RepresentationInfo] value
      def representation_info=(value)
        raise Teneo::Ingester::WorkflowAbort, 'Invalid RepresentationInfo object' unless value.nil? ||
            value.is_a?(Teneo::DataModel::RepresentationInfo)
        options[:representation_info_id] = value&.id
      end

      def representation_info
        return nil unless options[:representation_info_id]
        Teneo::DataModel::RepresentationInfo.find_by(id: options[:representation_info_id])
      end

      # noinspection RubyResolve
      def to_hash
        super.merge(self.representation_info.to_hash)
      end

    end

  end
end
