# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class RepresentationInfo < Base
    self.table_name = 'representation_infos'

    PRESERVATION_TYPES = %w'PRESERVATION_MASTER MODIFIED_MASTER DERIVATIVE_COPY'
    USAGE_TYPES = %w'VIEW THUMBNAIL'

    has_many :manifestations

    validates :name, :preservation_type, :usage_type, presence: true
    validates :preservation_type, inclusion: {in: PRESERVATION_TYPES}
    validates :usage_type, inclusion: {in: USAGE_TYPES}

  end

end
