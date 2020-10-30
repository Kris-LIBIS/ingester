# frozen_string_literal: true
require_relative 'base_sorted'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class Representation < BaseSorted
    self.table_name = 'representations'
    ranks :position, with_same: :ingest_model_id

    belongs_to :ingest_model

    belongs_to :representation_info
    belongs_to :access_right, optional: true

    belongs_to :from, class_name: 'Representation', inverse_of: :dependencies, optional: true
    has_many :dependencies, class_name: 'Representation', foreign_key: :from_id, inverse_of: :from, dependent: :nullify

    has_many :conversion_workflows, -> { rank(:position) }, inverse_of: :representation, dependent: :destroy

    def name
      label
    end

    def organization
      ingest_model&.organization
    end

    def self.from_hash(hash, id_tags = [:ingest_model_id, :label])
      model_name = hash.delete(:ingest_model)
      query = model_name ? { name: model_name } : { id: hash[:ingest_model_id] }
      ingest_model = record_finder Teneo::DataModel::IngestModel, query
      hash[:ingest_model_id] = ingest_model.id

      conversion_workflows = hash.delete(:conversion_workflows)

      item = super(hash, id_tags) do |item, h|
        if (from = h.delete(:from))
          item.from = record_finder Teneo::DataModel::Representation, from_id: hash[:ingest_model_id], label: from
        end
        if (access_right = h.delete(:access_right))
          item.access_right = record_finder Teneo::DataModel::AccessRight, name: access_right
        end
        if (representation_info = h.delete(:representation_info))
          item.representation_info = record_finder Teneo::DataModel::RepresentationInfo, name: representation_info
        end
      end

      if conversion_workflows
        old = item.conversion_workflows.map(&:id)
        conversion_workflows.each do |conversion_workflow|
          item.conversion_workflows <<
              Teneo::DataModel::ConversionWorkflow.from_hash(conversion_workflow.merge(representation_id: item.id))
        end
        (old - item.conversion_workflows.map(&:id)).each { |id| item.conversion_workflows.find(id)&.destroy! }
        item.save!
      end

      item
    end

  end

end
