class ChangeColumnTypeinBeerLocation < ActiveRecord::Migration
  def change
    change_column :beer_locations, :keg_size, :float
  end
end
