# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel
  # noinspection RailsParamDefResolve
  class Storage < Base
    self.table_name = 'storages'

    PURPOSE_LIST = %w'upload download workspace'

    belongs_to :organization, inverse_of: :storages
    belongs_to :storage_type, inverse_of: :storages

    validates :purpose, inclusion: { in: PURPOSE_LIST }

    include WithParameters

    def parameter_children
      [storage_type]
    end

    def service(reinitialize: false)
      @service = nil if reinitialize
      @service ||= storage_type.driver_class.
          constantize.new(parameters_list.transform_keys { |key| Parameter.reference_param(key) })
    end

    def self.from_hash(hash, id_tags = [:name, :organization_id])
      params = {}

      super(hash, id_tags) do |item, h|
        protocol = h.delete(:protocol)
        item.storage_type = record_finder(Teneo::DataModel::StorageType, protocol: protocol)
        params.merge!(params_from_values(protocol, h.delete(:values)))
      end.params_from_hash(params)
    end

  end
end
