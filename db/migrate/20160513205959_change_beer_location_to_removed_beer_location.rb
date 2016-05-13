class ChangeBeerLocationToRemovedBeerLocation < ActiveRecord::Migration
  def change
    rename_table :beer_locations, :removed_beer_locations
  end
end
