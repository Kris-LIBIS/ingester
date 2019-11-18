# frozen_string_literal: true

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class MimetypeChecker < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_process

        description 'Check the MIME type of the collected files.'

        help_text <<~STR
          With the help of this task a check can be performed if the files found are all of the expected type.

          Each file's MIME type will be checked against the regular expression in the 'mimetype_regexp' parameter. If a
          file's MIME type has not yet been determined, a warning will be logged and the file will be accepted without
          verifying the MIME type.

          If the 'mimetype_regexp' is not filled in, no MIME type checking will be performed at all.
        STR

        parameter pattern: nil,
                  description: 'Match files with MIME types that match the given regular expression. Ignored if empty.'

        recursive true
        item_types Teneo::Ingester::FileItem

        protected

        def process(item, *_args)
          pattern = parameter(:pattern)
          return if pattern.nil?
          debug "Checking MIME type against '/#{pattern}/'.", item
          pattern = Regexp.new(pattern) unless pattern.is_a? Regexp

          unless item.properties[:format_mimetype]
            warn 'Skipping file. MIME type not identified yet.', item
            return
          end

          unless item.properties[:format_mimetype] =~ pattern
            error 'File did not pass mimetype check.', item
            set_item_status(status: :failed, item: item)
          end

        end

      end

    end
  end
end
