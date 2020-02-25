# frozen_string_literal: true

require 'fileutils'
require_relative 'work_item'

module Teneo::Ingester

  # noinspection RailsParamDefResolve
  class FileItem < WorkItem

    include Libis::Workflow::FileItem

    before_destroy :delete_file

    def filename=(file)
      if (file_obj = to_file(file))
        raise "'#{file}' is not a file" unless file_obj.exist?
        properties[:storagename] = file
        file_obj.localize
        file = file_obj.local_path
      end
      raise "'#{file}' is not a file" unless File.exist?(file) && File.file?(file)
      super file
      save!
    end
    
    def storage_path
      return properties[:storagename] if properties[:storagename]
      to_storage_path(properties[:filename]) || properties[:filename]
    end

    def storage_obj
      to_file(properties[:storagename]) || File.new(properties[:filename])
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
          storagename: properties[:storagename] || fullpath
      )
    end

  end

end
