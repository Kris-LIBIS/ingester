# frozen_string_literal: true

require_relative "base/task"

module Teneo
  module Ingester
    module Tasks
      class CollectorFromList < Teneo::Ingester::Tasks::Base::Task
        taskgroup :collect

        description "Parse a file and process the entries as listed."

        help_text <<~STR
                    This collector is derived from DirCollector and therefore works similarly. These are the differences:

                    Files will not be parsed by reading a directory, but by reading the entries in a file. The file should contain
                    the file names one per line. No other information should be in this file. As the files will be processed in the
                    order they appear in the file, the 'sort' parameter is not used and frozen with false value.

                    Subdirectories can be processed too, but they have to be listed in the list file too. The subdirectory should
                    contain a list file with the same name if you want to process any files in the subdirectory too. The 'subdirs'
                    parameter will be still used the same way as for DirCollector for processing the directory entries.

                    Listing files in subdirectories in a parent directory's list file with the relative path, will process the files
                    but without creating any hierarchy for the subdirectories and files will be added to the parent directory. You
                    may use this feature for detailed control of your final structure, but things may become quite complex.
                  STR

        parameter location: ".", description: "Directory to start scanning in."
        parameter file_list: "files.list", description: "Name of the file containing the file names"

        recursive false
        item_types Teneo::DataModel::Package

        protected

        def process(item, *_args)
          @counter = 0
          collect(item, parameter(:location))
        end

        def collect(item, dir)
          return unless File.exist?(dir)
          return unless File.directory?(dir)
          dirlist = File.join(dir, parameter(:file_list))
          return unless File.exist?(dirlist)
          debug 'Collecting files from \'%s\'', item, dirlist
          add_files(item, dir, File.readlines(dirlist))
          item.save!
        end

        def add_files(item, dir, list)
          list.each do |file|
            file.strip!
            path = File.join(dir, file)
            unless File.exists?(path)
              warn "File '#{path}' not found.", item
              next
            end
            unless File.readable?(path)
              warn "Skipping file '#{path}' since it cannot be read.", item
              next
            end
            add(item, path)
          end
        end

        def add(item, file)
          child = nil
          if File.directory?(file)
            child = Teneo::DataModel::DirItem.new
            child.filename = file
            item.add_item(child)
            debug "Created Dir item `%s`", child, child.name
            collect(child, file)
          elsif File.file?(file)
            child = Teneo::DataModel::FileItem.new
            child.filename = file
            @counter += 1
            item.add_item(child)
            debug "Created File item `%s`", child, child.name
          end
          return unless child
          child.save!
          set_item_status(status: :done, item: child)
          status_progress(item: item.job, progress: @counter)
        end
      end
    end
  end
end
