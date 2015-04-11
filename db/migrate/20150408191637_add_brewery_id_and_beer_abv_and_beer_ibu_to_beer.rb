class AddBreweryIdAndBeerAbvAndBeerIbuToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :brewery_id, :integer
    add_column :beers, :beer_abv, :integer
    add_column :beers, :beer_ibu, :integer
  end
end
