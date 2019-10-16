# frozen_string_literal: true

require_relative 'work_item'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class FileItem < WorkItem

    include Libis::Workflow::FileItem

    def name
      self[:name]
    end

    def filename=(file)
      raise "'#{file}' is not a file" unless File.file? file
      self[:name] = File.basename(file)
      super
      save!
    end

  end

end
