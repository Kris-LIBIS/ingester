# frozen_string_literal: true

require_relative 'base_sorted'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class ConversionWorkflow < BaseSorted
    self.table_name = 'conversion_workflows'
    ranks :position, with_same: :representation_def_id

    belongs_to :representation_def

    has_many :conversion_tasks, -> { rank(:position) }, inverse_of: :conversion_workflow, dependent: :destroy
    has_many :converters, through: :conversion_tasks

    array_field :input_formats

    validates :representation_def_id, presence: true
    validates :name, presence: true, uniqueness: {scope: :representation_def_id}

    def organization
      representation_def&.organization
    end

    def tasks_info(_param_list = nil)
      conversion_tasks.each_with_object([]) do |task, result|
        converter = task.converter
        params = task.parameters_list.each_with_object({}) do |(key, value), hash|
          param_host, param_name = Parameter.reference_split(key)
          hash[param_name] = value if param_host == converter.name
        end
        result << {
            category: converter.category,
            class: converter.class_name,
            script: converter.script_name,
            # input_formats: converter.input_formats,
            # output_format: task.output_format,
            # name: converter.name,
            # description: converter.description,
            parameters: converter.parameter_values(true, false).merge(params).merge('format' => task.output_format)
        }
      end
    end

    def self.from_hash(hash, id_tags = [:representation_def_id, :name])
      representation_def_label = hash.delete(:representation_def)
      query = representation_def_label ? {label: representation_def_label} : {id: hash[:representation_def_id]}
      representation_def = record_finder Teneo::DataModel::RepresentationDef, query
      hash[:representation_def_id] = representation_def.id

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
