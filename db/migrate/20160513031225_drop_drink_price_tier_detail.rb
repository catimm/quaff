class DropDrinkPriceTierDetail < ActiveRecord::Migration
  def change
    drop_table :drink_price_tier_details
  end
end
