# frozen_string_literal: true

module Teneo
  module Ingester
    class Queue < DataModel::Base
      has_many :jobs
    end
  end
end