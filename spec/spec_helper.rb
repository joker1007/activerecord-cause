$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activerecord/cause'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

class User < ActiveRecord::Base; end

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate File.expand_path("../db/migrate", __FILE__), nil

require 'logger'
