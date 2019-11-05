require 'teneo/data_model'
require 'teneo/ingester'

dir = File.join __dir__, 'seeds'
# dir = File.join __dir__, '..', '..', 'data_server', 'db', 'seeds'
Teneo::Ingester::SeedLoader.new(dir)
