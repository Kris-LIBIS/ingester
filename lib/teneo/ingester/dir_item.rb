# frozen_string_literal: true

require_relative 'file_item'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class DirItem < WorkItem

    include Libis::Workflow::FileItem
    include Teneo::Ingester::Container

    def filename=(dir)
      raise "'#{dir}' is not a directory" unless File.directory? dir
      super
      save!
    end

    def template_vars
      super.merge(
          filename: filename,
          basename: File.basename(filename, '.*'),
          filepath: filepath,
          fullpath: fullpath,
          )
    end

  end

end
