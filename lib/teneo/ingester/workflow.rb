# frozen_string_literal: true

module Teneo
  module Ingester
    class Workflow
      include Libis::Workflow::Base::Workflow
      attr_reader :ingest_workflow

      def initialize(ingest_workflow)
        @ingest_workflow = ingest_workflow
      end

      def ingest_agreement
        ingest_workflow.ingest_agreement
      end

    end
  end
end