# encoding: utf-8

require 'libis-tools'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class VirusCheckerDir < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_process

        description 'Scan all files in a directory tree for viruses.'

        help_text <<~STR
          Scanning a complete directory tree for viruses can be much faster that performing a virusscan on each file
          individually, but it has the discadvantage that you cannot skip infected files and continue with the good
          files. This task will fail if any file in the directory tree is infected.
        STR

        parameter location: '.',
                  description: 'Directory to scan for viruses'

        recursive false
        item_types Teneo::DataModel::Package

        def process(item, *_args)

          raise Teneo::Ingester::WorkflowAbort, "Location does not exist: #{parameter(:location)}." unless Dir.exists?(parameter(:location))

          debug 'Scanning directory %s for viruses', item, parameter(:location)

          # noinspection RubyResolve
          cmd_options = Teneo::Ingester::Config.virusscanner['options'] + ['-r']
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Teneo::Ingester::Config.virusscanner[:command], *cmd_options, parameter(:location)
          unless result[:status]
            set_item_status(status: failed, item: item)
            raise Teneo::Ingester::WorkflowError, "Error during viruscheck: #{result[:err]}"
          end

          item.options['virus_checked'] = true
          debug 'Directory is clean', item

        end

      end

    end
  end
end
