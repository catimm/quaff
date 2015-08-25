class AddDontIncludeToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :dont_include, :boolean
  end
end
