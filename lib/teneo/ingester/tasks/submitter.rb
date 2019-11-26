# encoding: utf-8
require 'pathname'

require 'teneo/ingester'
require 'libis/metadata/dublin_core_record'
require 'libis/services/rosetta'
require 'libis/services/rosetta/collection_handler'

module Teneo
  module Ingester
    module Tasks

      class Submitter < Teneo::Ingester::Tasks::Base::Task

        taskgroup :ingest
        recursive true
        item_types Teneo::Ingester::IntellectualEntity

        description ''

        help_text <<~STR
        STR

        protected

        def pre_process(item, *_args)
          return false unless super && !!item.properties[:ingest_dir]
          stop_recursion
        end

        def process(item, *_args)
          if item.properties[:ingest_sip]
            debug 'Item already submitted: Deposit #%s SIP: %s', item,
                  item.properties[:ingest_dip], item.properties[:ingest_sip]
            return
          end
          debug "Found ingestable item. Subdir: #{item.properties[:ingest_dir]}", item
          producer = item.job.producer
          unless @deposit_service
            @deposit_service = Libis::Services::Rosetta::DepositHandler.new(Teneo::Ingester::Config[:rosetta_url])
            @deposit_service.authenticate(producer.agent,
                                          Teneo::Ingester::Initializer.decrypt(producer.password),
                                          producer.inst_code
            )
          end

          deposit_result = @deposit_service.submit(
              item.job.material_flow.ext_id,
              File.relative_path(item.job.material_flow.ingest_dir, item.properties[:ingest_dir]),
              producer.ext_id,
              run.id.to_s
          )
          debug 'Deposit result: %s', item , deposit_result
          item.properties[:ingest_sip] = deposit_result[:sip_id]
          item.properties[:ingest_dip] = deposit_result[:deposit_activity_id]
          item.properties[:ingest_date] = deposit_result[:creation_date]
          item.save!

          info 'Deposit #%s done. SIP: %s', item,
               item.properties[:ingest_dip], item.properties[:ingest_sip]

          item

        rescue Libis::Services::ServiceError => e
          raise Teneo::Ingester::WorkflowError, "SIP deposit failed: #{e.message}"

        rescue Exception => e
          raise Teneo::Ingester::WorkflowError, "SIP deposit failed: #{e.message} @ #{e.backtrace.first}"

        end

      end

    end
  end
end

