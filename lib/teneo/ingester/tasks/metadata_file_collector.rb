require 'teneo/ingester'
require 'libis/metadata/dublin_core_record'

require_relative 'base/metadata_search_collector'

module Teneo
  module Ingester
    module Tasks

      class MetadataFileCollector < Teneo::Ingester::Tasks::Base::MetadataSearchCollector

        parameter location: '.',
                  description: 'Directory where the metadata files can be found.'

        protected

        def search(term, item)
          metadata_file = File.join(parameter(:location), term)
          return nil unless File.exist?(metadata_file)

          begin
            return Libis::Metadata::DublinCoreRecord.new(metadata_file)
          rescue ArgumentError => e
            raise Teneo::WorkflowError, "Dublin Core file '#{metadata_file}' parsing error: #{e.message}"
          end
        end

      end

    end
  end
end