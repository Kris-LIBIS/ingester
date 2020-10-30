# frozen_string_literal: true
require 'teneo-data_model'
require 'rails'

module Teneo
  module DataModel
    #noinspection RubyResolve
    class Railtie < Rails::Railtie
      rake_tasks do
        Dir.glob(File.join(File.expand_path(__dir__), '*.rake')).each { |f| load f }
      end
    end
  end
end