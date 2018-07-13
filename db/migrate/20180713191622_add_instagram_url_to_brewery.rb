class AddInstagramUrlToBrewery < ActiveRecord::Migration[5.1]
  def change
    add_column :breweries, :instagram_url, :string
  end
end
