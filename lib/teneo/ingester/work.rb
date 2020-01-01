# frozen_string_literal: true

module Teneo
  module Ingester

    #noinspection RailsParamDefResolve
    class Work < DataModel::Base

      belongs_to :queue
      belongs_to :work_status
      belongs_to :worker, optional: true
      belongs_to :subject, polymorphic: true

    end

  end
end