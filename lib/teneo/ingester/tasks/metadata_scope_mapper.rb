require_relative 'base/mapping'
require_relative 'metadata_scope_collector'

module Teneo
  module Ingester
    module Tasks

      class MetadataScopeMapper < MetadataScopeCollector

        include Teneo::Ingester::Tasks::Base::Mapping

        parameter search_field: 'ScopeID',
                  description: 'Column name of the column in the mapping table that contains the search value.'

        def configure(opts)
          super
          set = Set.new(parameter(:mapping_headers))
          set << parameter(:search_field)
          parameter(:mapping_headers, set.to_a)
          parameter(:required_fields, [parameter(:mapping_key), parameter(:search_field)])
        end

        protected

        def get_search_term(item)
          lookup(super(item), parameter(:search_field))
        end

      end

    end
  end
end
