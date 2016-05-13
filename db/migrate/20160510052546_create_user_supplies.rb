class CreateUserSupplies < ActiveRecord::Migration
  def change
    create_table :user_supplies do |t|
      t.integer :user_id
      t.integer :beer_id
      t.integer :supply_type_id

      t.timestamps null: false
    end
  end
end
