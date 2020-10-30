# encoding: utf-8

require "libis/tools/extend/hash"

module Teneo::DataModel
  class IntellectualEntity < Item
    include Teneo::DataModel::Container

    before_destroy :delete_work_dir

    def delete_work_dir
      #noinspection RubyArgCount
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(parent.work_dir, name)
    end

    # @return [String]
    def ingest_type
      options[:ingest_type] || "METS"
    end

    # @param [String] value
    def ingest_type=(value)
      options[:ingest_type] = value
    end

    # @return [String]
    def pid
      properties[:pid]
    end

    # @param [String] value
    def pid=(value)
      properties[:pid] = value
    end

    # @return [Teneo::DataModel::IngestModel]
    def ingest_model
      im_list = job&.ingest_workflow.ingest_agreement.ingest_models
      return nil if im_list.nil? || im_list.empty?
      self.ingest_model = im_list.first unless options[:ingest_model_id]
      im_list.find_by(id: options[:ingest_model_id])
    end

    # @param [Teneo::DataModel::IngestModel] value
    def ingest_model=(value)
      raise Teneo::WorkflowAbort, "Ingest model should be part of same ingest agreement" unless value.nil? ||
                                                                                                value.is_a?(Teneo::DataModel::IngestModel) &&
                                                                                                  job.ingest_workflow.ingest_agreement_id == value.ingest_agreement_id
      options[:ingest_model_id] = value&.id
    end

    # @return [Teneo::DataModel::AccessModel]
    def access_right
      if options[:access_right_id]
        return Teneo::DataModel::AccessRight.find_by(id: options[:access_right_id])
      end
      ingest_model&.access_right
    end

    # @param [Teneo::DataModel::AccessRight] value
    def access_right=(value)
      raise Teneo::WorkflowAbort, "Invalid access right object" unless value&.is_a?(Teneo::DataModel::AccessRight)
      options[:access_right_id] = value&.id
    end

    # @return [Teneo::DataModel::RetentionPolicy]
    def retention_policy
      if options[:retention_policy_id]
        return Teneo::DataModel::RetentionPolicy.find_by(id: options[:retention_policy_id])
      end
      #noinspection RubyYardReturnMatch
      ingest_model&.retention_policy
    end

    # @param [Teneo::DataModel::RetentionPolicy] value
    def retention_policy=(value)
      raise Teneo::WorkflowAbort, "Invalid retention policy object" unless value&.is_a?(Teneo::DataModel::RetentionPolicy)
      options[:retention_policy_id] = value&.id
    end

    def representations
      items.where(type: Teneo::DataModel::Representation.name)
    end

    def originals
      items.where.not(type: Teneo::DataModel::Representation.name)
    end

    def representation(name_or_id)
      representations.where(id: name_or_id).first || self.representations.where(name: name_or_id).first
    end

    # @return [Teneo::DataModel::IngestModel]
    def get_ingest_model
      ingest_model || job&.ingest_workflow&.ingest_models.first
    end

    # @return [Teneo::DataModel::AccessRight]
    def get_access_right
      #noinspection RubyYardReturnMatch
      access_right || get_ingest_model&.access_right
    end

    # @return [Libis::Ingester::RetentionPeriod]
    def get_retention_policy
      retention_policy || get_ingest_model&.retention_policy.first
    end

    # @param [String] name
    def set_ingest_model(name)
      return self.ingest_model = nil if name.nil?
      im = job&.ingest_workflow.ingest_agreement.ingest_models.where(name: name).first
      raise Teneo::WorkflowError, "Ingest Model '#{name}' not found." unless im
      self.ingest_model = im
    end

    # @param [String] name
    def set_access_right(name)
      return self.access_right = nil if name.nil?
      ar = Teneo::DataModel::AccessRight.where(name: name).first
      raise Teneo::WorkflowError, "Access Right '#{name}' not found in the ingester database." unless ar
      self.access_right = ar
    end

    # noinspection RubyParameterNamingConvention
    def set_retention_policy(name)
      return self.retention_policy = nil if name.nil?
      rp = Teneo::DataModel::RetentionPolicy.find_by(name: name)
      raise Teneo::WorkflowError, "Retention Policy '#{name}' not found in the ingester database." unless rp
      self.retention_policy = rp
    end
  end
end
