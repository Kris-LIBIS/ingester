# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class RetentionPolicy < Base
    self.table_name = 'retention_policies'

    has_many :ingest_models

    validates :name, :ext_id, presence: true
    validates :name, uniqueness: true
  end

end
