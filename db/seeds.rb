require 'teneo/data_model'

dir = File.join __dir__, 'seeds'
# dir = File.join __dir__, '..', '..', 'data_server', 'db', 'seeds'
Teneo::DataModel::SeedLoader.new(dir)
