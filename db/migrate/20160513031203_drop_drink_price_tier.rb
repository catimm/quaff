class DropDrinkPriceTier < ActiveRecord::Migration
  def change
    drop_table :drink_price_tiers
  end
end
