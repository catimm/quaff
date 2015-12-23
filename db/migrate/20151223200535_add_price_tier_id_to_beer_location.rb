class AddPriceTierIdToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :price_tier_id, :integer
  end
end
