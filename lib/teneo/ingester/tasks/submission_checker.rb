# encoding: utf-8
require 'pathname'

require 'teneo/ingester'
require 'libis/metadata/dublin_core_record'
require 'libis/services/rosetta'
require 'libis/services/rosetta/collection_handler'

module Teneo
  module Ingester
    module Tasks

      class SubmissionChecker < Teneo::Ingester::Tasks::Base::Task

        taskgroup :ingest

        description ''

        help_text <<~STR
        STR


        protected

        def process(item)
        end

      end

    end
  end
end

