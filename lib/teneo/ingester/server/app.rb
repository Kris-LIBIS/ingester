# frozen_string_literal: true

require 'roda'
require 'awesome_print'
require 'ostruct'
require 'json'

require_relative 'api'

module Teneo
  module Ingest
    module Server

      class App < Roda

        ROLE = 'ingester'.freeze

        key = File.read(File.join(Teneo::Ingester::ROOT_DIR, 'key.bin'), mode: 'rb')

        use Rack::Session::Cookie, secret: key

        plugin :public, root: 'static'
        plugin :empty_root
        plugin :heartbeat, path: '/status'
        plugin :json
        plugin :json_parser
        plugin :all_verbs
        plugin :halt
        plugin :request_headers
        plugin :sessions,
               cookie_options: {http_only: true, same_site: :strict},
               secret: key,
               key: 'teneo.ingester'

        plugin :hash_routes

        route do |r|
          r.hash_routes
        end

      end

    end
  end
end
