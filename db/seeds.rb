require 'teneo/data_model'
require 'teneo/ingester'
require 'bcrypt'

ON_TTY = false

Teneo::Ingester::SeedLoader.new(dir)

dir = File.join __dir__, 'seeds'
Teneo::DataModel::SeedLoader.new(dir, tty: ON_TTY)

dir = File.join __dir__, 'seeds', 'code_tables'
Teneo::DataModel::SeedLoader.new(dir, tty: ON_TTY)

dir = File.join __dir__, 'seeds', 'workflows'
Teneo::DataModel::SeedLoader.new(dir, tty: ON_TTY)

dir = File.join __dir__, 'seeds', 'kadoc'
Teneo::DataModel::SeedLoader.new(dir, tty: ON_TTY)

Teneo::DataModel::Account.create_with(password: 'abc123').find_or_create_by(email_id: 'admin@libis.be')
Teneo::DataModel::Account.create_with(password: '123abc').find_or_create_by(email_id: 'info@kadoc.be')
