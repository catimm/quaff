class RemoveAltNameOneAndAltNameTwoAndAltNameThreeFromBrewery < ActiveRecord::Migration
  def change
    remove_column :breweries, :alt_name_one, :string
    remove_column :breweries, :alt_name_two, :string
    remove_column :breweries, :alt_name_three, :string
  end
end
