# frozen_string_literal: true

require 'fileutils'
require_relative 'work_item'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class FileItem < WorkItem

    include Libis::Workflow::FileItem

    before_destroy :delete_file

    def filename=(file)
      raise "'#{file}' is not a file" unless File.file? file
      super
      save!
    end

    def delete_file
      super
      properties.keys
          .select { |key| key.to_s =~ /^format_/ }
          .each { |key| properties.delete(key) }
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
