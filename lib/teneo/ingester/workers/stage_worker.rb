# frozen_string_literal: true
require 'teneo-ingester'
require 'sidekiq'

module Teneo
  module Ingester

    class StageWorker
      include Sidekiq::Worker
      sidekiq_options retry: false, dead: false

      def perform(stage, item)
      end

      def self.push_job(schema: 5, queue: 'default')
        client_push(class: self, queue: queue, retry: false, args: schema)
      end
    end

  end
end