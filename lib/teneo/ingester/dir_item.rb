# frozen_string_literal: true

require_relative 'file_item'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class DirItem < WorkItem

    include Libis::Workflow::FileItem

    def filename=(dir)
      raise "'#{dir}' is not a directory" unless File.directory? dir
      super
    end

  end

end
