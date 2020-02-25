# frozen_string_literal: true
require 'teneo-ingester'
require 'sidekiq'

module Teneo
  module Ingester

    class JobWorker
      include Sidekiq::Worker
      sidekiq_options retry: 0

      def perform(package_id, *args)
        package = Teneo::DataModel::Package.find_by(id: package_id)
        package.execute *args
      end

      def self.push_job(schema: 5, queue: 'default')
        client_push(class: self, queue: queue, retry: false, args: schema)
      end
    end

  end
end