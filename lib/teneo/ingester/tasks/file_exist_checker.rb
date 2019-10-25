require 'libis/workflow'

module Teneo
  module Ingester

    class FileExistChecker < Teneo::Ingester::Task

      taskgroup :preprocessor

      description 'Check if a file exists'

      help <<-STR.align_left
        This task can be used when the collector creates FileItem objects from some external source without checking if
        the file referenced does exist. For each FileItem in the ingest run tree, a check will be performed if the file
        referenced by the object does exist and can be read. If not an error will be logged and the workflow will abort.
      STR

      parameter item_types: [Teneo::Ingester::FileItem], frozen: true

      protected

      def process(item, *_args)
        return item if File.exists?(item.fullpath) && File.readable?(item.fullpath)

        set_item_status(status: :failed, item: item)
        raise Teneo::Ingester::WorkflowError, "File '#{item.filepath}' does not exist."
      end

    end

  end
end
