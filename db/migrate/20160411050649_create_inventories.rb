class CreateInventories < ActiveRecord::Migration
  def change
    create_table :inventories do |t|
      t.integer :beer_id
      t.integer :stock
      t.integer :demand
      t.integer :order_queue

      t.timestamps null: false
    end
  end
end
