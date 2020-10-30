# frozen_string_literal: true
require_relative 'base'
require_relative 'storage_resolver'

require 'order_as_specified'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class IngestStage < Base
    extend OrderAsSpecified
    self.table_name = 'ingest_stages'

    STAGE_LIST = Teneo::DataModel::StageWorkflow::STAGE_LIST

    with_options inverse_of: :ingest_stages do |model|
      model.belongs_to :ingest_workflow
      model.belongs_to :stage_workflow
    end

    validates :stage, presence: true, inclusion: {in: STAGE_LIST}, uniqueness: {scope: :ingest_workflow_id}
    validates_each :stage_workflow do |record, attr, value|
      record.errors.add attr, 'stage does not match' unless value.nil? || value.stage == record.stage
    end

    def name
      stage
    end

    include StorageResolver

    def organization
      ingest_workflow&.organization
    end

    def self.from_hash(hash, id_tags = [:ingest_workflow_id, :stage])
      ingest_workflow = hash.delete(:ingest_workflow)
      query = ingest_workflow ? {name: ingest_workflow} : {id: hash[:ingest_workflow_id]}
      ingest_workflow = record_finder Teneo::DataModel::IngestWorkflow, query
      hash[:ingest_workflow_id] = ingest_workflow.id
      super(hash, id_tags) do |item, h|
        if (stage_workflow = h.delete(:workflow))
          item.stage_workflow = record_finder Teneo::DataModel::StageWorkflow, name: stage_workflow
        end
      end
    end

  end

end
