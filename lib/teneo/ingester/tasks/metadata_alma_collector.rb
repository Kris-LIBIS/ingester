require 'teneo/ingester'

require_relative 'base/alma_search'
require_relative 'base/metadata_search_collector'

module Teneo
  module Ingester
    module Tasks

      class MetadataAlmaCollector < ::Teneo::Ingester::Tasks::Base::MetadataSearchCollector

        include Teneo::Ingester::Tasks::Base::AlmaSearch

        parameter converter: 'Kuleuven'

      end

    end
  end
end