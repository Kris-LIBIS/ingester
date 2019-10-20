# encoding: utf-8

require 'libis-tools'

module Teneo
  module Ingester

      class VirusChecker < Teneo::Ingester::Task

        taskgroup :preprocessor

        parameter item_types: [Teneo::Ingester::FileItem], frozen: true

        def pre_process(item)
          super
          skip_processing_item if item.options[:virus_checked]
        end

        def process(item)

          debug 'Scanning file for viruses'

          # noinspection RubyResolve
          cmd_options = Teneo::Ingester::Config.virusscanner[:options]
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Teneo::Ingester::Config.virusscanner[:command], *cmd_options, item.fullpath
          raise Teneo::Ingester::WorkflowError, "Error during viruscheck: #{result[:err]}" unless result[:status]

          item.options[:virus_checked] = true
          debug 'File is clean'

        end

      end

  end
end
