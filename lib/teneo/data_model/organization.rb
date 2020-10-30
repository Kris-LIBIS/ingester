# frozen_string_literal: true
require 'active_support/core_ext/object/with_options'

require_relative 'base'
require_relative 'storage_resolver'

module Teneo
  module DataModel
    # noinspection RailsParamDefResolve
    class Organization < Base
      self.table_name = 'organizations'

      with_options dependent: :destroy, inverse_of: :organization do |model|
        model.has_many :memberships
        model.has_many :storages
        model.has_many :ingest_agreements
      end

      has_many :users, through: :memberships

      accepts_nested_attributes_for :memberships, allow_destroy: true

      validate :safe_name

      include StorageResolver

      def organization
        self
      end

      def self.from_hash(hash)
        storages = hash.delete(:storages)
        item = super(hash, [:name, :inst_code])
        if storages
          old = item.storages.map(&:id)
          storages.each do |name, data|
            item.storages << Teneo::DataModel::Storage.from_hash(data.merge(name: name, organization_id: item.id))
          end
          (old - item.storages.map(&:id)).each { |id| item.storages.find(id)&.destroy! }
          item.save!
        end
        item
      end

    end

  end
end
