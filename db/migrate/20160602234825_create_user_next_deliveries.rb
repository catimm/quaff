class CreateUserNextDeliveries < ActiveRecord::Migration
  def change
    create_table :user_next_deliveries do |t|
      t.integer :user_id
      t.integer :inventory_id
      t.integer :user_drink_recommendation_id

      t.timestamps null: false
    end
  end
end
