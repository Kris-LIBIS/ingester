# frozen_string_literal: true

require 'teneo/data_model/conversion_workflow'

module Teneo::DataModel

  class ConversionWorkflow

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

  end
end
