class RemoveBreweryIdFromAltBeerName < ActiveRecord::Migration
  def change
    remove_column :alt_beer_names, :brewery_id, :integer
  end
end
