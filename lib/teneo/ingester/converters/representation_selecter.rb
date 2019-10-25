# frozen_string_literal: true

require 'libis/format/library'

module Teneo
  module Ingester

    class RepresentationSelecter < Teneo::Ingester::Converter

      taskgroup :selecter

      description 'Initial selecter that populates a representation.'

      help <<~STR.align_left
        This selecter is intended to be in the first spot in the conversion workflow. It is used to get files into
        the representation ready to be processed by other converters. Its constructor takes both the input container
        (typically an InterllectualEntity or another representation) and the output container (the new representation).
        There are 4 parameter options for this converter task:
        - formats: an array with formats or format groups against which any file's format will be checked. If the
                   format list is empty, it will match any file format
        - filename: a regular expression that will be used to match each file's filename against. Only files whose
                    file name matches the regex will be selected. An empty string (the default) matches any file name.
        - keep_structure: a boolean that determines if the folder structure of the source container will be copied over
                          to the target container or not. Note that only the structure that will contain selected files
                          will be copied over.
        - copy: a boolean that decides what action will be performed on a selection candidate. If true (the default),
                a new file item will be created with a copy of the original file. If false the original file item will
                be moved into the target container and will still reference the original file. Conversion tasks further
                down the conversion workflow will most likely remove its source item along with the file, so you will
                most likely want to copy the files.
      STR

      parameter formats: [], datatype: Array, description: 'List of formats and format groups that need to match.'
      parameter filename: '', description: 'Regular expression for the filenames to match.'
      parameter keep_structure: true, description: 'Keep the same folder structure in the selection.'
      parameter copy: true, description: 'Copy or move the source files into the selection.'

      protected

      def process(item, *args)
        itemset = args.first
        check_item_type(itemset, Array)
        select_items(itemset, [item],
                     regex: Regexp.new(parameter(:filename) || ''),
                     formats: parameter(:formats))
        item.items
      end

      def select_items(items, target_list, regex:, formats:)
        items.find_each(batch_size: 100) do |item|
          if item.is_a?(Teneo::Ingester::ItemGroup)
            target_list.push(item) if parameter(:keep_structure)
            select_items(item.items, target_list, regex: regex, formats: formats)
            target_list.pop
          elsif item.is_a?(Teneo::Ingester::FileItem)
            next unless match_file(item, regex: regex, formats: formats)
            path.each_with_index do |p, i|
              next if i == 0
              next if p.parent == path[i - 1]
              p = p.dup
              path[i - 1] << p
              p.save!
              path[i] = p
            end
            item = item.dup if parameter(:copy)
            path.last << item
            item.save!
          end
        end
      end

      def match_file(file, regex:, formats:)
        return false unless regex.source.empty? || file.filename =~ regex
        return true if formats.empty?
        mimetype = file.properties['mimetype']
        unless mimetype
          error "File format not yet identified.", file
          raise WorkflowError "File format identification is required for file selection in conversion "
        end
        format_info = Libis::Format::Library.get_info_by(:mimetype, mimetype)
        unless format_info
          warn "File format mimetype %s not registered in Format library.", file, mimetype
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
