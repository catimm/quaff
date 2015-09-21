class AddBreweryStateLongToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :brewery_state_long, :string
  end
end
