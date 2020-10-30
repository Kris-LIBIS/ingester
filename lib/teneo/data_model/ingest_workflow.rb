# frozen_string_literal: true
require_relative 'base'
require_relative 'storage_resolver'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class IngestWorkflow < Base
    self.table_name = 'ingest_workflows'

    belongs_to :ingest_agreement, inverse_of: :ingest_workflows

    has_many :packages, -> { order(id: :asc) }, dependent: :destroy
    has_many :ingest_stages, -> { order_as_specified(stage: Teneo::DataModel::IngestStage::STAGE_LIST) }, dependent: :destroy
    has_many :stage_workflows, through: :ingest_stages, dependent: :destroy

    has_many :parameter_refs, as: :with_param_refs, class_name: 'Teneo::DataModel::ParameterRef', dependent: :destroy

    validates :name, presence: true
    validate :safe_name

    include StorageResolver

    def organization
      ingest_agreement&.organization
    end

    include WithParameters

    def parameter_children
      stage_workflows
    end

    def self.from_hash(hash, id_tags = [:ingest_agreement_id, :name])
      agreement_name = hash.delete(:ingest_agreement)
      query = agreement_name ? { name: agreement_name } : { id: hash[:ingest_agreement_id] }
      ingest_agreement = record_finder Teneo::DataModel::IngestAgreement, query
      hash[:ingest_agreement_id] = ingest_agreement.id

      params = hash.delete(:parameters) || {}
      stages = hash.delete(:stages) || []

      super(hash, id_tags).tap do |item|
        old = item.ingest_stages.map(&:id)
        stages.each do |stage|
          params.merge!(params_from_values(stage[:workflow], stage.delete(:values)))
          stage[:ingest_workflow_id] = item.id
          item.ingest_stages << Teneo::DataModel::IngestStage.from_hash(stage)
        end
        (old - item.ingest_stages.map(&:id)).each { |id| item.ingest_stages.find(id).destroy! }
      end.params_from_hash(params)
    end

  end

end
