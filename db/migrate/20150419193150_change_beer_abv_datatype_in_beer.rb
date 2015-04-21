class ChangeBeerAbvDatatypeInBeer < ActiveRecord::Migration
  def change
    change_column :beers, :beer_abv, :float
  end
end
