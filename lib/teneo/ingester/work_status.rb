# frozen_string_literal: true

module Teneo
  module Ingester
    class WorkStatus < DataModel::Base
      has_many :works
    end
  end
end