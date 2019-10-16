# frozen_string_literal: true

require 'teneo/data_model/package'

module Teneo::DataModel

  class Package

    include Libis::Workflow::Job

    def tasks
      ingest_workflow.tasks_info(parameters_list)
    end

    def make_run(opts = {})
      run = Teneo::DataModel::Run.create(name: run_name, package: self, options: opts)
      runs << run
      run.save!
      run
    end

    def last_run
      runs.order_by(id: :desc).first
    end

    def <<(item)
      item.parent = self
    end

    def item_list
      items.reload
      items.to_a
    end

  end
end
