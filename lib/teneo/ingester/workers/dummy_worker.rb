# frozen_string_literal: true
require 'teneo-ingester'
require 'sidekiq'

module Teneo
  module Ingester

    class DummyWorker
      include Sidekiq::Worker
      sidekiq_options retry: false, dead: false

      def perform(schema)
        Teneo::Ingester::Initializer.instance.workflow_world.trigger(Teneo::Ingester::Tasks::Dummy, schema)
      end
    end

  end
end