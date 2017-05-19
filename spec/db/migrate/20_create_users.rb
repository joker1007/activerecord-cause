if ActiveRecord.version < Gem::Version.new("5.0.0")
  class CreateUsers < ActiveRecord::Migration
    def change
      create_table :users do |t|
        t.string :name
        t.references :auth_user, polymorphic: true

        t.timestamps null: false
      end
    end
  end
else
  class CreateUsers < ActiveRecord::Migration[5.0]
    def change
      create_table :users do |t|
        t.string :name
        t.references :auth_user, polymorphic: true

        t.timestamps null: false
      end
    end
  end
end
