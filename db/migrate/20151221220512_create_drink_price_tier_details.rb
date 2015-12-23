class CreateDrinkPriceTierDetails < ActiveRecord::Migration
  def change
    create_table :drink_price_tier_details do |t|
      t.integer :drink_price_tier_id
      t.integer :drink_size
      t.decimal :drink_cost, :precision => 5, :scale => 2

      t.timestamps null: false
    end
  end
end
