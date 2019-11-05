# frozen_string_literal: true

module Teneo
  module Ingester

    class ConversionRunner < Libis::Workflow::TaskGroup

      parameter item_types: [Teneo::Ingester::Representation], datatype: Array,
                description: 'Item types to process.'

      parameter formats: [], datatype: Array, description: 'List of formats and format groups that need to match.'
      parameter filename: '', description: 'Regular expression for the filenames to match.'
      parameter keep_structure: true, description: 'Keep the same folder structure in the selection.'
      parameter copy: true, description: 'Copy or move the source files into the selection.'

      attr_accessor :action

      def allowed_item_types
        [Teneo::Ingester::Representation]
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
        Regexp.new(parameter(:filename) || '')
      end

      def copy_files
        parameter(:copy)
      end

      def keep_structure
        parameter(:keep_structure)
      end

      protected

      def pre_process(item, *_args)
        return false unless item.is_a?(Teneo::Ingester::Representation)
        super
      end

      def post_process(item, *_args)
        item.save!
        item.reload
      end

      def process(item, *args)

      end

    end
  end
end
