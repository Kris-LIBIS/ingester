require 'teneo/data_model'
require 'teneo/ingester'

dir = File.join __dir__, 'seeds'
Teneo::Ingester::SeedLoader.new(dir)
