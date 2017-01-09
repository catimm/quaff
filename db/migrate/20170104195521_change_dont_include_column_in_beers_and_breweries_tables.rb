class ChangeDontIncludeColumnInBeersAndBreweriesTables < ActiveRecord::Migration
  def change
    rename_column :beers, :dont_include, :vetted
    rename_column :beers_temp, :dont_include, :vetted
    rename_column :breweries, :dont_include, :vetted
    rename_column :breweries_temp, :dont_include, :vetted
  end
end
