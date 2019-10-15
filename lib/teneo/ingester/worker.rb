# frozen_string_literal: true
require 'teneo-ingester'
require 'sidekiq'

module Teneo
  module Ingester

    class Worker
      include Sidekiq::Worker

      def perform(package, config = {})
        # Create run
        # Configure run
        # Execute run
      end
    end

  end
end