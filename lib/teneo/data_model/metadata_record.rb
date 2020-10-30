# frozen_string_literal: true
require_relative 'base'
require_relative 'serializers/hash_serializer'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class MetadataRecord < Base
    self.table_name = 'metadata_records'

    belongs_to :item

  end

end
