# frozen_string_literal: true

require 'libis/workflow'

module Teneo
  module Ingester

    class FileMimetypeChecker < Teneo::Ingester::Task

      taskgroup :preprocessor

      description 'Check the MIME type of the collected files.'

      help <<-STR.align_left
        With the help of this task a check can be performed if the files found are all of the expected type.

        Each file's MIME type will be checked against the regular expression in the 'mimetype_regexp' parameter. If a
        file's MIME type has not yet been determined, a warning will be logged and the file will be accepted without
        verifying the MIME type.

        If the 'mimetype_regexp' is not filled in, no MIME type checking will be performed at all.
      STR

      parameter mimetype_regexp: nil,
                description: 'Match files with MIME types that match the given regular expression. Ignored if empty.'

      parameter item_types: [Teneo::Ingester::FileItem], frozen: true

      protected

      def process(item, *_args)
        filter = parameter(:mimetype_regexp)
        return if filter.nil?
        debug "Checking MIME type against '/#{filter}/'.", item
        filter = Regexp.new(filter) unless filter.is_a? Regexp

        unless item.properties[:mimetype]
          warn 'Skipping file. MIME type not identified yet.', item
          return
        end

        unless item.properties[:mimetype] =~ filter
          error  'File did not pass mimetype check.', item
          set_item_status(status: :failed, item: item)
        end

      end

    end

  end
end
