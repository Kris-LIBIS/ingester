# frozen_string_literal: true
require_relative 'base'
require_relative 'storage_resolver'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class IngestAgreement < Base
    self.table_name = 'ingest_agreements'

    include StorageResolver

    with_options dependent: :destroy, inverse_of: :ingest_agreement do |model|
      model.has_many :ingest_models
      model.has_many :ingest_workflows
    end

    with_options inverse_of: :ingest_agreements do |model|
      model.belongs_to :organization
      model.belongs_to :material_flow
      model.belongs_to :producer
    end

    has_many :packages, through: :ingest_workflows

    accepts_nested_attributes_for :material_flow
    accepts_nested_attributes_for :producer

    array_field :contact_ingest
    array_field :contact_collection
    array_field :contact_system

    validates :name, presence: true
    validate :safe_name
    validates_each :producer, :material_flow do |record, attr, value|
      record.errors.add attr, 'organization does not match' unless value.nil? || value.inst_code == record.organization.inst_code
    end

    def self.from_hash(hash, id_tags = [:organization_id, :name])
      org_name = hash.delete(:organization)
      query = org_name ? { name: org_name } : { id: hash[:organization_id] }
      organization = record_finder Teneo::DataModel::Organization, query
      hash[:organization_id] = organization.id
      ingest_models = hash.delete(:ingest_models)
      ingest_workflows = hash.delete(:ingest_workflows)
      item = super(hash, id_tags) do |item, h|
        if (producer = h.delete(:producer))
          item.producer = record_finder Teneo::DataModel::Producer, inst_code: organization.inst_code, name: producer
        end
        if (material_flow = h.delete(:material_flow))
          item.material_flow = record_finder Teneo::DataModel::MaterialFlow, inst_code: organization.inst_code, name: material_flow
        end
      end
      if ingest_models
        old = item.ingest_models.map(&:id)
        ingest_models.each do |ingest_model|
          item.ingest_models << Teneo::DataModel::IngestModel.from_hash(ingest_model.merge(ingest_agreement_id: item.id))
        end
        (old - item.ingest_models.map(&:id)).each { |id| item.ingest_models.find(id)&.destroy! }
        item.save!
      end
      if ingest_workflows
        old = item.ingest_workflows.map(&:id)
        ingest_workflows.each do |ingest_workflow|
          item.ingest_workflows << Teneo::DataModel::IngestWorkflow.from_hash(ingest_workflow.merge(ingest_agreement_id: item.id))
        end
        (old - item.ingest_workflows.map(&:id)).each { |id| item.ingest_workflows.find(id)&.destroy! }
        item.save!
      end
      item
    end

  end

end
