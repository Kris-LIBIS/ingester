# frozen_string_literal: true
require_relative 'base_sorted'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class ConversionTask < BaseSorted
    self.table_name = 'conversion_tasks'
    ranks :position, with_same: :conversion_workflow_id

    belongs_to :conversion_workflow, inverse_of: :conversion_tasks

    belongs_to :converter

    validates :conversion_workflow_id, presence: true
    validates :name, presence: true, uniqueness: {scope: :conversion_workflow_id}

    def organization
      conversion_workflow&.organization
    end

    include WithParameters

    def parameter_children
      [converter]
    end

    def self.from_hash(hash, id_tags = [:conversion_workflow_id, :name])
      workflow_name = hash.delete(:conversion_workflow)
      query = workflow_name ? {name: workflow_name} : {id: hash[:conversion_workflow_id]}
      conversion_workflow = record_finder Teneo::DataModel::ConversionWorkflow, query
      hash[:conversion_workflow_id] = conversion_workflow.id
      params = {}

      super(hash, id_tags) do |item, h|
        if (converter = h.delete(:converter))
          item.converter = record_finder Teneo::DataModel::Converter, name: converter
          params.merge!(params_from_values(converter, h.delete(:values)))
        end
      end.params_from_hash(params)
    end

  end
end
