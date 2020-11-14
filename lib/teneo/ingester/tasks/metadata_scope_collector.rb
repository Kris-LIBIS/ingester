# frozen_string_literal: true

require 'teneo/ingester'
require 'libis/services/scope/search'
require 'libis/metadata/dublin_core_record'

require_relative 'base/metadata_search_collector'

module Teneo
  module Ingester
    module Tasks
      class MetadataScopeCollector < Teneo::Ingester::Tasks::Base::MetadataSearchCollector
        parameter converter: 'Scope'
        parameter term_type: 'REPCODE',
                  desrciption: 'Type of term value that will be passed',
                  constraint: %w(REPCODE ID)
        parameter scope_db: nil, datatype: :string,
                  description: 'Scope database URL, default is set in configuration'
        parameter scope_user: nil, datatype: :string,
                  description: 'Scope database user, default is set in configuration'
        parameter scope_passwd: nil, datatype: :string,
                  description: 'Scope database password, default is set in configuration'

        protected

        def search(term, item)
          unless @scope
            @scope = ::Libis::Services::Scope::Search.new
            @scope.connect(
              parameter(:scope_user) || Teneo::Ingester::Config['scope_user'],
              parameter(:scope_passwd) || Teneo::Ingester::Config['scope_passwd'],
              parameter(:scope_db) || Teneo::Ingester::Config['scope_db']
            )
          end

          debug "Querying scope with term '#{term}' and type '#{parameter(:term_type)}'", item
          @scope.query(term, type: parameter(:term_type))

          @scope.next_record do |doc|
            debug "Found record with title '#{doc.value('//dc:title')}", item
            return ::Libis::Metadata::DublinCoreRecord.new(doc.to_xml)
          end
        rescue Exception => e
          raise Teneo::WorkflowError, "Scope request failed: #{e.message}"
        end
      end
    end
  end
end
