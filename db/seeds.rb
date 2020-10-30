require "teneo/data_model"
require "teneo/ingester"
require "bcrypt"

ON_TTY = true

loader = Teneo::Ingester::TaskLoader.new(tty: ON_TTY)

loader.load_converters
loader.load_tasks

dir = File.join __dir__, "seeds"
loader.load_dir(dir)

dir = File.join __dir__, "seeds", "code_tables"
loader.load_dir(dir)

dir = File.join __dir__, "seeds", "workflows"
loader.load_dir(dir)

dir = File.join __dir__, "seeds", "kadoc"
loader.load_dir(dir)

user = Teneo::DataModel::User.find_by(email: "admin@libis.be")
user.update(admin: true)
user.password = "abc123"
user.save

user = Teneo::DataModel::User.find_by(email: "teneo.libis@gmail.com")
user.update(admin: false)
user.password = "123abc"
user.save

user = Teneo::DataModel::User.find_by(email: "info@kadoc.be")
user.update(admin: false)
user.password = "123abc"
user.save
