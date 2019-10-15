# frozen_string_literal: true

require 'teneo/data_model/run'

module Teneo::DataModel

  class Run

    include Libis::Workflow::Run

    def tasks
      ingest_workflow.tasks_info(parameters_list)
    end

    def job
      package
    end

  end
end
