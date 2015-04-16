class CreateAuthUsers < ActiveRecord::Migration
  def change
    create_table :auth_users do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
