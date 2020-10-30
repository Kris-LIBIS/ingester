# encoding: utf-8
require "pathname"

require "teneo/ingester"
require "libis/metadata/dublin_core_record"
require "libis/services/rosetta"
require "libis/services/rosetta/collection_handler"

module Teneo
  module Ingester
    module Tasks
      class SubmissionChecker < Teneo::Ingester::Tasks::Base::Task
        taskgroup :ingest
        recursive true
        item_types Teneo::DataModel::IntellectualEntity

        description ""

        help_text <<~STR
                  STR

        retry_count 60
        retry_interval 60

        protected

        def pre_process(item, *_args)
          return false unless super && item_status(item) != :done && !!item.properties[:ingest_sip]
          stop_recursion
        end

        def process(item, *_args)
          check_item(item)
          stop_recursion
          item
        end

        def check_item(item)
          # noinspection RubyResolve
          unless @sip_handler
            @sip_handler = Libis::Services::Rosetta::SipHandler.new(Teneo::Ingester::Config[:rosetta_url])
            producer = item.job.producer
            @sip_handler.authenticate(producer.agent,
                                      Teneo::DataModel::Initializer.decrypt(producer.password),
                                      producer.inst_code)
          end
          sip_info = @sip_handler.get_info(item.properties[:ingest_sip])
          unless sip_info
            error "Failed to retrieve SIP status information", item
            raise Teneo::WorkflowError, "No SIP status"
          end
          item.properties[:ingest_status] = sip_info.to_hash
          item_status = case sip_info.status
            when "FINISHED"
              :done
            when "DRAFT", "APPROVED", "INPROCESS", "CREATED", "WAITING", "ACTIVE"
              :async_wait
            when "IN_HUMAN_STAGE", "IN_TA"
              :async_halt
            else
              :failed
            end
          info "SIP: %s - Module: %s Stage: %s Status: %s", item,
               item.properties[:ingest_sip], sip_info.module, sip_info.stage, sip_info.status
          assign_ie_numbers(item, @sip_handler.get_ies(item.properties[:ingest_sip])) if item_status == :done
          set_item_status(item: item, status: item_status)
        end

        def assign_ie_numbers(item, number_list)
          if item.is_a?(Teneo::DataModel::IntellectualEntity)
            ie = number_list.shift
            item.pid = ie.pid if ie
            info "Assigned PID #{item.pid} to IE item.", item
          else
            item.items.map { |i| assign_ie_numbers(i, number_list) }
          end
        end
      end
    end
  end
end
