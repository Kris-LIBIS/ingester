# frozen_string_literal: true

require 'libis-format'
require 'libis/tools/extend/hash'
require 'yard/core_ext/file'

require_relative 'base/format'
require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class FormatIdentifier < Teneo::Ingester::Tasks::Base::Task

        include Base::Format

        taskgroup :pre_process

        description 'Tries to determine the format of a file.'

        help_text <<~STR
          This task will perform the format identification on any FileItem object that is submitted to the task. It uses
          the format identification algorithms in Libis::Format::Identifier. If a format cannot be determined, the MIME
          type 'application/octet-stream' will be set and a warning message is logged.

          Note that this task will identify each file individually. The format identification tools Droid, Fido, ... will
          be launched for each file individually, which does take a significant time. For a more performant version,
          consider using FormatDirIdentifier if possible.
        STR

        parameter format_options: {}, type: 'hash',
                  description: 'Set of options to pass on to the format identifier tool'

        recursive true
        item_types Teneo::Ingester::FileItem

        protected

        def process(item, *_args)
          format_list = Libis::Format::Identifier.get(item.filepath, parameter(:format_options))
          process_messages(format_list, item)
          apply_formats(item, format_list[:formats])
        end

      end

    end
  end
end
