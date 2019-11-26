# frozen_string_literal: true

require 'libis/format/library'

require_relative 'base/selecter'

module Teneo
  module Ingester
    module Converters

      class RepresentationSelecter < Teneo::Ingester::Converters::Base::Selecter

        description 'Initial selecter that populates a representation.'

        help_text <<~STR
          This selecter is intended to be in the first spot in the conversion workflow. It is used to get files into
          the representation ready to be processed by other converters. Its constructor takes both the input container
          (typically an InterllectualEntity or another representation) and the output container (the new representation).

          The parent taskgroup (ConversionRunner) provides this task with 4 configuration parameters:
          - formats: an array with formats or format groups against which any file's format will be checked. If the
                format list is empty, it will match any file format
          - filename_regex: a regular expression that will be used to match each file's filename against. Only files
                whose file name matches the regex will be selected. An empty string (the default) matches any file name.
          - keep_structure: a boolean that determines if the folder structure of the source container will be copied over
                to the target container or not. Note that only the structure that will contain selected files will be
                copied over.
          - copy_files: a boolean that decides what action will be performed on a selection candidate. If true 
                (the default), a new file item will be created with a copy of the original file. If false the original 
                file item will be moved into the target container and will still reference the original file. Conversion 
                tasks further down the conversion workflow will most likely remove its source item along with the file, 
                so you will most likely want to copy the files.
        STR

        protected

        def select_items(source_items, target_group)
          item_grabber(source_items, [target_group],
                       regex: parent.filename_regex,
                       formats: parent.formats, copy: parent.copy_files)
        end

        def item_grabber(items, path, regex:, formats:, copy:)
          path = [path] unless path.is_a?(Array)
          items.find_each(batch_size: 100) do |item|
            if item.is_a?(Teneo::Ingester::ItemGroup)
              item_grabber(item.items, path, regex: regex, formats: formats, copy: copy)
            elsif item.is_a?(Teneo::Ingester::DirItem)
              path.push(item) if parent.keep_structure
              item_grabber(item.items, path, regex: regex, formats: formats, copy: copy)
              path.pop if parent.keep_structure
            elsif item.is_a?(Teneo::Ingester::FileItem)
              next unless match_file(item, regex: regex, formats: formats)
              # materialize the candidate target tree
              path.each_with_index do |p, i|
                next if i == 0
                next if p.parent == path[i - 1]
                path[i] = p.dup_dir_item(p, path[i - 1])
              end
              if copy
                item = item.dup
                # FileItem is duplicated, but the file itself is not, so the new Item does not own the file
                item.own_file(false)
              end
              path.last << item
              item.save!
            end
          end
        end

        def dup_dir_item(item, parent)
          dir = Teneo::Ingester::DirItem.new(name: item.name)
          parent << dir
          path = dir.work_path
          FileUtils.mkpath(path)
          dir.filename = path
          dir.save!
        end

        def match_file(file, regex:, formats:)
          return false unless regex.source.empty? || file.filename =~ regex
          return true if formats.empty?
          mimetype = file.properties[:format_mimetype]
          unless mimetype
            error "File format not yet identified.", file
            raise Teneo::Ingester::WorkflowError "File format identification is required for file selection in conversion "
          end
          format_info = Libis::Format::Library.get_info_by(:mimetype, mimetype)
          unless format_info
            warn "File format mimetype '%s' not registered in Format library.", file, mimetype
            return false
          end
          format_name = format_info[:name]
          group = format_info[:category]
          check_list = [format_name, group].compact.map { |v| [v.to_s, v.to_sym] }.flatten
          (formats & check_list).size > 0
        end

      end
    end
  end
end
