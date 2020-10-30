# frozen_string_literal: true

require 'teneo-data_model'
require_relative '../ingester'

module Teneo
  module Ingester
    module Server

      autoload :Account, 'teneo/ingest_server/account'
      autoload :App, 'teneo/ingester/server/app'

    end
  end
end