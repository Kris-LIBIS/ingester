# frozen_string_literal: true

require 'teneo/data_model/ingest_workflow'

module Teneo::DataModel

  class IngestWorkflow

    def tasks_info(param_list)
      stage_workflows.each_with_object([]) do |workflow, result|
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
