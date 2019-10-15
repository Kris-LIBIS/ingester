# frozen_string_literal: true
require 'libis-tools'

module Teneo
  module Ingester

    # noinspection RubyConstantNamingConvention
    Config = ::Libis::Workflow::Config

    Config.define_singleton_method(:require_all) do |dir|
      Dir.glob(File.join(dir, '*.rb')).each do |filename|
        # noinspection RubyResolve
        require filename
      end
    end

    # noinspection RubyResolve
    Config[:status_log] = Teneo::DataModel::StatusLog
    Config.require_all(File.join(__dir__, 'tasks'))
    Config[:virusscanner] = {command: 'echo', options: []}
    Config[:work_dir] = '/tmp'
    Config[:ingest_dir] = '/tmp'

  end
end
