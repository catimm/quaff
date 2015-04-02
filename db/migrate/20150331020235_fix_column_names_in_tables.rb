class FixColumnNamesInTables < ActiveRecord::Migration
  def change
    rename_column :beer_locations, :current, :beer_is_current
    rename_column :beers, :name, :beer_name
    rename_column :beers, :type, :beer_type
    rename_column :beers, :rating, :beer_rating
  end
end
