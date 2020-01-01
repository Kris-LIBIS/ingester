# frozen_string_literal: true

module Teneo
  module Ingester

    #noinspection RailsParamDefResolve
    class Queue < DataModel::Base

      has_many :works, class_name: 'Teneo::Ingester::Work'

    end

  end
end