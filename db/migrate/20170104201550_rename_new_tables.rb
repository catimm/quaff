class RenameNewTables < ActiveRecord::Migration
  def change
    rename_table :beers_temp, :temp_beers
    rename_table :breweries_temp, :temp_breweries
    rename_table :beer_brewery_collabs_temp, :temp_beer_brewery_collabs
  end
end
