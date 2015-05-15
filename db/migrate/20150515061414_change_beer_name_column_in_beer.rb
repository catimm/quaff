class ChangeBeerNameColumnInBeer < ActiveRecord::Migration
  def change
    rename_column :beers, :beer_type, :beer_type_old_name
  end
end
