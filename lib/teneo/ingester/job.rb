# frozen_string_literal: true
require 'libis-workflow'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/slice'

module Teneo
  module Ingester
    class Job
      include Libis::Workflow::Base::Job
      attr_reader :submitter, :package, :run, :workflow, :config

      def initialize(config)
        @submitter = nil
        @package = nil
        @run = nil
        @workflow = nil
        @config = configure(config)
      end

      def configure(config)
        cfg = config.deep_stringify_keys
        submitter_id = cfg.delete('submitter')
        @submitter = Teneo::DataModel::User.find_by(id: submitter_id)
        raise Teneo::Ingester::Error, 'Could not find User with ID: "%s"', submitter_id unless @submitter
        package_id = cfg.delete('package')
        @package = Teneo::DataModel::Package.find_by(id: package_id)
        raise Teneo::Ingester::Error, 'Could not find Package with ID: "%s"', package_id unless @package
        @workflow = Teneo::Ingester::Workflow.new(@package.ingest_workflow)
        @config = cfg
      end

      def name
        "#{organization.name}-#{@package.name}"
      end

      def ingest_workflow
        @package.ingest_workflow
      end

      def ingest_agreement
        workflow.ingest_agreement
      end

      def organization
        ingest_agreement.organization
      end

      def producer
        ingest_agreement.producer
      end

      def material_flow
        ingest_agreement.material_flow
      end

      def ingest_dir
        organization.ingest_dir
      end

      def run
        @run ||= Teneo::Ingester::Run.new job: self, config: @config
      end

      def parameters_per_task
        result = {}
        ingest_workflow.parameter_refs
        @package.parameter_values.each do |parameter_value|

        end
      end

      protected

      def create_run_object

      end

    end
  end
end