# encoding: utf-8

require "libis/metadata"

require_relative "task"

module Teneo
  module Ingester
    module Tasks
      module Base
        class MetadataCollector < Teneo::Ingester::Tasks::Base::Task
          taskgroup :pre_ingest
          item_types Teneo::DataModel::IntellectualEntity, Teneo::DataModel::Collection
          recursive true

          parameter converter: "",
                    description: "Dublin Core metadata converter to use.",
                    constraint: ["", "Kuleuven", "Flandrica", "Scope"]

          protected

          def process(item, *_args)
            record = get_record(item)
            unless record
              return
            end
            record = convert_metadata(record)
            assign_metadata(item, record)
          rescue Teneo::Error
            raise
          rescue Exception => e
            error "Error getting metadata: %s", item, e.message
            debug "At: %s", item, e.backtrace.first
            set_item_status(item: item, status: :failed)
            raise Teneo::WorkflowError, "MetadataCollector failed."
          end

          def get_record(item)
            nil
          end

          private

          def assign_metadata(item, record)
            metadata_record = Teneo::DataModel::MetadataRecord.new
            metadata_record.format = "DC"
            metadata_record.data = record.to_xml
            # noinspection RubyResolve
            item.metadata_record = metadata_record
            info 'Metadata added to \'%s\'', item, item.name
            item.save!
          end

          def convert_metadata(record)
            return record if parameter(:converter).blank?
            mapper_class = "Libis::Metadata::Mappers::#{parameter(:converter)}".constantize
            unless mapper_class
              raise Teneo::WorkflowAbort, "Metadata converter class `#{parameter(:converter)}` not found."
            end
            record.extend mapper_class
            record.to_dc
          end
        end
      end
    end
  end
end
