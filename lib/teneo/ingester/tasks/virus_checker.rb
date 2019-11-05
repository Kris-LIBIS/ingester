# encoding: utf-8

require 'libis-tools'

require_relative 'base/task'

module Teneo
  module Ingester
    module Tasks

      class VirusChecker < Teneo::Ingester::Tasks::Base::Task

        taskgroup :pre_process

        recursive true
        item_types Teneo::Ingester::FileItem

        def pre_process(item, *_args)
          return false if item.options[:virus_checked]
          super
        end

        def process(item, *_args)

          debug 'Scanning file for viruses', item

          # noinspection RubyResolve
          cmd_options = Teneo::Ingester::Config.virusscanner[:options]
          # noinspection RubyResolve
          result = Libis::Tools::Command.run Teneo::Ingester::Config.virusscanner[:command], *cmd_options, item.fullpath
          unless result[:status]
            set_item_status(status: :failed, item: item)
            raise Teneo::Ingester::WorkflowError, "Error during viruscheck: #{result[:err]}"
          end

          item.options[:virus_checked] = true
          debug 'File is clean', item

        end

      end

    end
  end
end
