# frozen_string_literal: true

module Teneo
  module Ingester
    class ConversionRunner < Teneo::Workflow::TaskGroup
      parameter formats: [], datatype: Array, description: "List of formats and format groups that need to match."
      parameter filename: "", description: "Regular expression for the filenames to match."
      parameter keep_structure: true, description: "Keep the same folder structure in the selection."
      parameter copy: true, description: "Copy or move the source files into the selection."
      parameter on_convert_error: "FAIL", type: :string, constraint: %w'FAIL DROP COPY',
                description: "Action to take when a file conversion fails.",
                help: <<~STR
                  Valid values are:

                  FAIL
                  : report this as an error and stop processing the item

                  DROP
                  : report this as an error and continue without the file

                  COPY
                  : report the error and copy the source file instead

                   Note that dropping the file may cause errors later, e.g. with empty representations.
                STR

      attr_accessor :action

      def allowed_item_types
        [Teneo::DataModel::Representation]
      end

      def execute(item, *_args)
        @action = :start
        item = super
        item.reload
        item
      end

      def formats
        parameter(:formats) || []
      end

      def filename_regex
        Regexp.new(parameter(:filename) || "")
      end

      def copy_files
        parameter(:copy)
      end

      def keep_structure
        parameter(:keep_structure)
      end

      protected

      def pre_process(item, *_args)
        return false unless item.is_a?(Teneo::DataModel::ItemGroup)
        super
      end

      def post_process(item, *_args)
        item.save!
        item.reload
      end
    end
  end
end
