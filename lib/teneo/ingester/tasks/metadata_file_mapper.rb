require "teneo/ingester"
require "libis/metadata/dublin_core_record"

require_relative "base/mapping"
require_relative "metadata_file_collector"

module Teneo
  module Ingester
    module Tasks
      class MetadataFileMapper < MetadataFileCollector
        include Teneo::Ingester::Tasks::Base::Mapping

        parameter metadata_file_field: "metadata_file",
                  description: "The header value of the column that contains the name of the metadata file."

        protected

        def search(term, item)
          file_name = lookup(term, parameter(:metadata_file_field))
          unless file_name
            warn "No matching metadata file name found for #{term}.", item
            return nil
          end
          metadata_file = File.join(parameter(:location), file_name)
          unless File.exist?(metadata_file)
            raise Teneo::WorkflowError, "File #{metadata_file} not found."
          end

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
