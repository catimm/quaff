class AddSlugFieldsToBeerAndBrewery < ActiveRecord::Migration[5.1]
  def change
    add_column :breweries, :slug, :string
    add_column :beers, :slug, :string
    
    add_index :breweries, :slug, :unique => true
    add_index :beers, :slug, :unique => true
  end
end
