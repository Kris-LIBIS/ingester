# frozen_string_literal: true
require_relative 'base'
require_relative 'serializers/symbol_serializer'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class StatusLog < Base
    self.table_name = 'status_logs'

    default_scope { order(created_at: :asc) }

    belongs_to :item
    belongs_to :run

    serialize :status, Serializers::SymbolSerializer

  end

end
