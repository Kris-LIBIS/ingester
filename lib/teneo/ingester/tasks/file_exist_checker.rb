# frozen_string_literal: true

require "teneo/workflow"

require_relative "base/task"

module Teneo
  module Ingester
    module Tasks
      class FileExistChecker < Teneo::Ingester::Tasks::Base::Task
        taskgroup :pre_process

        description "Check if a file exists"

        help_text <<~STR
                    This task can be used when the collector creates FileItem objects from some external source without checking if
                    the file referenced does exist. For each FileItem in the ingest run tree, a check will be performed if the file
                    referenced by the object does exist and can be read. If not an error will be logged and the workflow will abort.
                  STR

        recursive true
        item_types Teneo::DataModel::FileItem

        protected

        def process(item, *_args)
          return item if File.exists?(item.fullpath) && File.readable?(item.fullpath)

          set_item_status(status: :failed, item: item)
          raise Teneo::WorkflowError, "File '#{item.filepath}' does not exist."
        end
      end
    end
  end
end
