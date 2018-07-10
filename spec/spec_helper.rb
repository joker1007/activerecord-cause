$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activerecord/cause'

ActiveRecord::Base.configurations[:test] = {
  adapter: "sqlite3",
  database: ":memory:"
}
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[:test])

class AuthUser < ActiveRecord::Base; end

class User < ActiveRecord::Base
  belongs_to :auth_user, polymorphic: true

  def auth_user_name
    auth_user.name
  end
end

ActiveRecord::Migration.verbose = false
if ActiveRecord.version >= Gem::Version.new("5.2.0")
  ActiveRecord::MigrationContext.new(File.expand_path("../db/migrate", __FILE__)).up
else
  ActiveRecord::Migrator.migrate File.expand_path("../db/migrate", __FILE__), nil
end

require 'logger'
