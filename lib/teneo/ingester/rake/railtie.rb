# frozen_string_literal: true
require 'teneo-ingester'
require 'rails'

module Teneo
  module Ingester

    #noinspection RubyResolve
    class Railtie < Rails::Railtie
      railtie_name :teneo_ingester

      rake_tasks do
        path = File.expand_path(__dir__)
        Dir.glob(File.join(path, 'rake', '*.rake')).each { |f| load f }
      end

    end
  end
end