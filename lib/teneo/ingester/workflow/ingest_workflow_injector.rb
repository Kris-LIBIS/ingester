# frozen_string_literal: true

require 'teneo/data_model/ingest_workflow'

module Teneo::DataModel

  class IngestWorkflow

    before_destroy :delete_work_dir

    def delete_work_dir
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(ingest_agreement.work_dir, name)
    end

    def ingest_dir
      File.join(ingest_agreement.ingest_dir, name)
    end

    def tasks_info(param_list)
      ingest_stages.each_with_object([]) do |stage, result|
        workflow = stage.stage_workflow
        result << {
            name: workflow.stage,
            long_name: workflow.name,
            description: workflow.description,
            autorun: stage.autorun,
            tasks: workflow.tasks_info(param_list)
        }
      end
    end

  end
end
