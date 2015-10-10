class AddShortBeerNameToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :short_beer_name, :string
  end
end
