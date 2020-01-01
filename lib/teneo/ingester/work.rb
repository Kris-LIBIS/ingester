# frozen_string_literal: true

module Teneo
  module Ingester

    #noinspection RailsParamDefResolve
    class Work < DataModel::Base

      belongs_to :queue, class_name: 'Teneo::Ingester::Queue'
      belongs_to :work_status, class_name: 'Teneo::Ingester::WorkStatus'
      belongs_to :worker, optional: true, class_name: 'Teneo::Ingester::Worker'
      belongs_to :subject, polymorphic: true

    end

  end
end