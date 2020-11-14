# frozen_string_literal: true

module Teneo::DataModel
  class Representation < Item
    include Container

    before_destroy :delete_work_dir

    def delete_work_dir
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(parent.work_dir, name)
    end

    def access_right=(value)
      raise Teneo::WorkflowAbort, "Invalid AccessRight object" unless value&.is_a?(Teneo::DataModel::AccessRight)
    end

    def access_right
      return nil unless options[:access_right_id]
      Teneo::DataModel::AccessRight.find_by(id: options[:access_right_id])
    end

    def representation_info=(value)
      raise Teneo::WorkflowAbort, "Invalid RepresentationInfo object" unless value&.is_a?(Teneo::DataModel::RepresentationInfo)
    end

    def representation_info
      return nil unless options[:representation_info_id]
      Teneo::DataModel::RepresentationInfo.find_by(id: options[:respresentation_info_id])
    end

    def to_hash
      super.merge(self.representation_info.to_hash)
    end
  end
end
