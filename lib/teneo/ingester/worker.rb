# frozen_string_literal: true

module Teneo
  module Ingester
    class Worker < DataModel::Base
      has_many :works
    end
  end
end
