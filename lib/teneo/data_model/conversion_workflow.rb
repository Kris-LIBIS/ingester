# frozen_string_literal: true
require_relative 'base_sorted'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class ConversionWorkflow < BaseSorted
    self.table_name = 'conversion_workflows'
    ranks :position, with_same: :representation_id

    belongs_to :representation

    has_many :conversion_tasks, -> { rank(:position) }, inverse_of: :conversion_workflow, dependent: :destroy
    has_many :converters, through: :conversion_tasks

    array_field :input_formats

    validates :representation_id, presence: true
    validates :name, presence: true, uniqueness: {scope: :representation_id}

    def organization
      representation&.organization
    end

    def self.from_hash(hash, id_tags = [:representation_id, :name])
      representation_label = hash.delete(:representation)
      query = representation_label ? {label: representation_label} : {id: hash[:representation_id]}
      representation = record_finder Teneo::DataModel::Representation, query
      hash[:representation_id] = representation.id

      tasks = hash.delete(:tasks) || []

      super(hash, id_tags).tap do |item|
        old = item.conversion_tasks.map(&:id)
        if tasks
          tasks.each do |task|
            task[:conversion_workflow_id] = item.id
            item.conversion_tasks << Teneo::DataModel::ConversionTask.from_hash(task)
          end
        end
        (old - item.conversion_tasks.map(&:id)).each { |id| item.conversion_tasks.find(id)&.destroy! }
      end
    end

  end

end
