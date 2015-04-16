class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.references :auth_user, polymorphic: true

      t.timestamps null: false
    end
  end
end
