# frozen_string_literal: true

require 'teneo/data_model/run'

module Teneo::DataModel

  class Run

    include Libis::Workflow::Run

    before_destroy :delete_ingest_dir

    def delete_ingest_dir
      FileUtils.rmtree(ingest_dir) if Dir.exists?(ingest_dir)
    end

    def ingest_dir
      File.join(package.ingest_workflow.ingest_dir, name)
    end

    def job
      package
    end

  end
end
