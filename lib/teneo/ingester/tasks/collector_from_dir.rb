# frozen_string_literal: true

require 'naturally'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class CollectorFromDir < Teneo::Ingester::Tasks::Base::Task

        taskgroup :collect

        description 'Parse a directory tree and collect all files and folders in it.'

        help_text <<~STR
          The directory tree at parameter 'location' will be parsed and ingest objects will be created for files and
          folders found. The behaviour can be extensively configured with the parameters:

          All files will be used, unless the 'selection' parameter is filled in. It should contain a regular expression
          and only files that match the expression will be used for FileItem object creation. Files not matching will be
          silently ignored. Similarly, the optional 'ignore' parameter can contain a regular expression that causes the 
          files that match to be ignored and only files that do not match will pass the test. Both the file name and the
          file path are tested against the regular expressions. Note that only files found are checked against the regular
          expression of the 'selection' parameter, while also the subdirectories found will be checked against the regular
          expression of the 'ignore' parameter, thus allowing to completely ignore subfolders and its contents in the
          collector.

          The parameter 'subdirs' decides how subdirectories are processed. The following values are possible:

          ignore
          : any subdirectory will be ignored and the task will only process files in the top directory

          recursive
          : for each subdirectory, an ingest object is created and files in the subdirectory will be part of
            the folder object. The folder structure will be recreated in the ingest objects

          flatten
          : the task will not create an ingest object for the subdirectories, but will parse it contents and
            further process the files and folders in it. This has the same effect as if all files would reside in the same
            top-level directory

          For performance reasons, the collector limits the number of files it can collect. By default this is set to
          5000 as the ingest will start to get exponentially slower with files > 5000. This can be overwritten if 
          required with the 'file_limit' parameter.

          By default, this collector will perform a natural sort (https://en.wikipedia.org/wiki/Natural_sort_order) on 
          the directory entries found. This behaviour can be turned off by setting the 'sort' parameter to false. Note 
          that in that case the entries will be listed in the order as provided by the underlying file system, which may
          be hard to control. If you want the objects ingested in a specific order, consider the DirListCollector task
          instead.
        STR

        parameter location: '.',
                  description: 'Directory to start scanning in.'
        parameter sort: true, description: 'Sort entries.'
        parameter selection: '',
                  description: 'Only select files that match the given regular expression. Ignored if empty.'
        parameter ignore: nil,
                  description: 'File pattern (Regexp) of files that should be ignored.'
        parameter subdirs: 'ignore', constraint: %w[ignore recursive flatten],
                  description: 'How to collect subdirs'
        parameter file_limit: 5000,
                  description: 'Maximum number of files to collect.',
                  help: 'If the number of files found exceeds this limit, the task will fail.'

        recursive false
        item_types Teneo::DataModel::Package

        protected

        def process(item, *_args)
          @counter = 0
          collect(item, parameter(:location))
        end

        def collect(item, dir)
          debug 'Collecting files in \'%s\'', item, dir
          add_files(item, dir, Dir.entries(dir))
          item.save!
        end

        def add_files(item, dir, list)
          reg = parameter(:selection)
          reg = (reg and !reg.empty?) ? Regexp.new(reg) : nil
          ignore = parameter(:ignore) && Regexp.new(parameter(:ignore))
          list = Naturally.sort_by_block(list) { |x| x.gsub('.', '.0.').gsub('_', '.') } if parameter(:sort)
          list.each do |file|
            file.strip!
            next if file =~ /^\.{1,2}$/
            path = File.join(dir, file)
            if reg && File.file?(path) && !((file =~ reg) || (path =~ reg))
              next if ignore and (file =~ ignore || path =~ ignore)
              warn "Found file '#{File.basename(path)}' in folder '#{File.dirname(path)}' that did not match the selection regex.", item
              next
            end
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
            case parameter(:subdirs).to_s.downcase
            when 'recursive'
              child = Teneo::Ingester::DirItem.new
              child.filename = file
              item.add_item(child)
              debug 'Created Dir item `%s`', child, child.name
              collect(child, file)
            when 'flatten'
              collect(item, file)
            else
              info "Ignoring subdir #{file}.", item
            end
          elsif File.file?(file)
            child = Teneo::Ingester::FileItem.new
            child.filename = file
            @counter += 1
            item.add_item(child)
            debug 'Created File item `%s`', child, child.name
          end
          if @counter > parameter(:file_limit)
            fatal_error 'Number of files found exceeds limit (%d). Consider splitting into separate runs or raise limit.',
                        item, parameter(:file_limit)
            raise Teneo::Ingester::WorkflowAbort, 'Number of files exceeds preset limit.'
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
