# frozen_string_literal: true

require 'teneo/data_model/organization'

module Teneo::DataModel

  class Organization

    before_destroy :delete_work_dir

    def delete_work_dir
      #noinspection RubyArgCount
      FileUtils.rmdir(work_dir) if Dir.exists?(work_dir)
    end

    def work_dir
      File.join(Teneo::Ingester::Config[:work_dir], name)
    end

    def log_dir
      File.join(Teneo::Ingester::Config[:log_dir], name)
    end

  end
end
