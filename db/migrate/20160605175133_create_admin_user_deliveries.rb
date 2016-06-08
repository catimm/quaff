class CreateAdminUserDeliveries < ActiveRecord::Migration
  def change
    create_table :admin_user_deliveries do |t|
      t.integer :user_id
      t.integer :beer_id
      t.integer :inventory_id
      t.boolean :new_drink
      t.float :projected_rating
      t.string :style_preference
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
