# frozen_string_literal: true

require_relative 'file_item'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class DirItem < Item
    include Teneo::Workflow::FileItem
    include Teneo::DataModel::Container

    def filename=(dir)
      if (dir_obj = to_dir(dir))
        raise "'#{dir}' is not a directory" unless dir_obj.exist?
        properties[:storagename] = dir
        properties[:filename] = dir.driver_path
        self.name ||= File.basename(properties[:filename])
        properties[:size] = dir_obj.size
        properties[:modification_time] = dir_obj.mtime
      else
        raise "'#{dir}' is not a directory" unless File.exist?(dir) && File.directory?(dir)
        super
      end
      save!
    end

    def storage_path
      return properties[:storagename] if properties[:storagename]
      to_storage_path(properties[:filename]) || properties[:filename]
    end

    def storage_obj
      to_dir(properties[:storagename]) || Dir.new(properties[:filename])
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
