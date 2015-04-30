class AddBreweryBeersToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :brewery_beers, :integer
  end
end
