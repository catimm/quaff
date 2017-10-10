class CreateDistiInventories < ActiveRecord::Migration
  def change
    create_table :disti_inventories do |t|
      t.integer :beer_id
      t.integer :size_format_id
      t.decimal :drink_cost
      t.decimal :drink_price
      t.integer :distributor_id
      t.integer :disti_item_number
      t.string :disti_upc

      t.timestamps null: false
    end
  end
end
