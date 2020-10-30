# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class Producer < Base
    self.table_name = 'producers'

    scope :for_organization, -> (id) do
      org = id.is_a?(Teneo::DataModel::Organization) ? id : Teneo::DataModel::Organization.find(id)
      where(inst_code: org.inst_code)
    end

    has_many :ingest_agreements,
             dependent: :destroy,
             inverse_of: :material_flow

    validates :name, :ext_id, :inst_code, :agent, :password, presence: true
    validates :name, uniqueness: {scope: :inst_code, message: 'already taken for this inst_code'}

    def self.from_hash(hash, id_tags = [:inst_code, :name])
      super(hash, id_tags)
    end
  end

end
