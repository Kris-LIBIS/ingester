# frozen_string_literal: true

require 'teneo/data_model/ingest_workflow'

module Teneo::DataModel

  class IngestWorkflow

    def tasks_info(param_list)
      stage_workflows.each_with_object([]) do |workflow, result|
        params = param_list.each_with_object({}) do |(key, value), hash|
          param_host, param_name = Parameter.reference_split(key)
          hash[param_name] = value if param_host == workflow.name
        end
        result << {
            name: workflow.stage,
            long_name: workflow.name,
            description: workflow.description,
            tasks: workflow.tasks_info(param_list)
        }
      end
    end

  end
end
