# frozen_string_literal: true

require 'teneo/data_model/package'

module Teneo::DataModel

  class Package

    include Libis::Workflow::Job

    before_destroy :delete_work_dir

    def delete_work_dir
      #noinspection RubyArgCount
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(ingest_workflow.work_dir, name)
    end

    def ingest_dir
      File.join(ingest_workflow.ingest_dir, name)
    end

    def log_dir
      File.join(ingest_workflow.log_dir, name)
    end

    def parents
      []
    end

    def filelist
      []
    end

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
      item.insert_at :last
    end

    alias add_item <<

    def each(&block)
      items.each(&block)
    end

    def size
      items.size
    end

    alias count size

    def item_list
      items.reload
      items.to_a
    end

    def producer
      ingest_workflow.ingest_agreement.producer
    end

    def material_flow
      ingest_workflow.ingest_agreement.material_flow
    end

  end
end
