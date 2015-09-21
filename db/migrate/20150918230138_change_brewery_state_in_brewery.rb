class ChangeBreweryStateInBrewery < ActiveRecord::Migration
  def change
    rename_column :breweries, :brewery_state, :brewery_state_short
  end
end
