class ChangeDataTypeInBeer < ActiveRecord::Migration
  def change
    change_column :beers, :beer_rating, :float
  end
end
