# frozen_string_literal: true
require 'libis-workflow'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/string/inflections'

module Teneo
  module Ingester

    class Run
      include Libis::Workflow::Base::Run
      attr_reader :job, :config, :run_object, :tasks

      def initialize(job:, config:)
        @job = job
        @tasks = []
        cfg = config.symbolize_keys
        @config = cfg.slice! :start_date, :log_to_file, :log_level, :config
        cfg[:start_date] ||= Time.now
        @run_object = Teneo::DataModel::Run.new cfg
        @job.package << @run_object
        @run_object.save!
      end

      def name
        "#{job.name}-#{@run_object.id}"
      end

      def run(action)

      end

      private

      def start_date=(date)
        @run_object.start_date = date
        @run_object.save!
      end

      def create_tasks
        ingest_workflow = job.ingest_workflow

        run_object.config.each do |stage, action|

          ingest_task = ingest_workflow.ingest_tasks.find_by(stage: stage)
          ingest_task.stage_workflow.stage_tasks.each do |stage_task|
            tasks << {
                stage: stage,
                task: stage_task.task.class_name.constantize.new(nil),
                action: action
            }
          end
        end
      end

    end

  end
end