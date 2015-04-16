$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activerecord/cause'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

class AuthUser < ActiveRecord::Base; end

class User < ActiveRecord::Base
  belongs_to :auth_user, polymorphic: true

  def auth_user_name
    auth_user.name
  end
end

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate File.expand_path("../db/migrate", __FILE__), nil

require 'logger'
