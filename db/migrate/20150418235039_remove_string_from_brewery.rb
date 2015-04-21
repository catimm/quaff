class RemoveStringFromBrewery < ActiveRecord::Migration
  def change
    remove_column :breweries, :string, :string
  end
end
