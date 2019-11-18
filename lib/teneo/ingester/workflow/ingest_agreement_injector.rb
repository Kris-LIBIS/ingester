# frozen_string_literal: true

require 'teneo/data_model/ingest_agreement'

module Teneo::DataModel

  class IngestAgreement

    before_destroy :delete_work_dir

    def delete_work_dir
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(organization.work_dir, name)
    end

    def ingest_dir
      File.join(material_flow.ingest_dir, name)
    end

  end
end
