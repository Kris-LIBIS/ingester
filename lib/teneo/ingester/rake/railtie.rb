# frozen_string_literal: true
require 'teneo-ingester'
require 'rails'

module Teneo
  module Ingester
    #noinspection RubyResolve
    class Railtie < Rails::Railtie
      rake_tasks do
        Dir.glob(File.join(File.expand_path(__dir__), '*.rake')).each { |f| load f }
      end
    end
  end
end