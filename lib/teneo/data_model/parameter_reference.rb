# frozen_string_literal: true
require_relative 'base'

module Teneo::DataModel

  # noinspection RailsParamDefResolve
  class ParameterReference < Base
    self.table_name = 'parameter_references'

    belongs_to :source, class_name: Parameter.name, touch: true
    belongs_to :target, class_name: Parameter.name, touch: true

  end

end