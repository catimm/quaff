class AddShortBreweryNameToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :short_brewery_name, :string
  end
end
