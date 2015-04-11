class ChangeColumnTypeOnBeer < ActiveRecord::Migration
  def change
    change_column :beers, :beer_abv, :decimal
  end
end
