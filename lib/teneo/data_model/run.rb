# frozen_string_literal: true
require_relative 'base'
require_relative 'serializers/hash_serializer'
require_relative 'storage_resolver'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class Run < Base

    self.table_name = 'runs'

    belongs_to :package
    belongs_to :user, optional: true
    has_many :status_logs, dependent: :destroy
    has_many :message_logs, inverse_of: :run, dependent: :destroy

    serialize :config, Serializers::HashSerializer
    serialize :options, Serializers::HashSerializer
    serialize :properties, Serializers::HashSerializer

    include StorageResolver

    def organization
      package&.organization
    end

  end

end
