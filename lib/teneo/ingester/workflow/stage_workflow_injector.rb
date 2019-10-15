# frozen_string_literal: true

require 'teneo/data_model/stage_workflow'

module Teneo::DataModel

  class StageWorkflow

    def tasks_info(param_list)
      tasks.each_with_object([]) do |task, result|
        params = param_list.each_with_object({}) do |(key, value), hash|
          param_host, param_name = Parameter.reference_split(key)
          hash[param_name] = value if param_host == task.name
        end
        result << {
            class: task.class_name,
            name: task.name,
            description: task.description,
            parameters: task.parameter_values(true, false).merge(params)
        }
      end
    end

  end
end
