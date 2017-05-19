if ActiveRecord.version < Gem::Version.new("5.0.0")
  class CreateAuthUsers < ActiveRecord::Migration
    def change
      create_table :auth_users do |t|
        t.string :name

        t.timestamps null: false
      end
    end
  end
else
  class CreateAuthUsers < ActiveRecord::Migration[5.0]
    def change
      create_table :auth_users do |t|
        t.string :name

        t.timestamps null: false
      end
    end
  end
end
