class AddAltNameOneAndAltNameTwoAndAltNameThreeToBrewery < ActiveRecord::Migration
  def change
    add_column :breweries, :alt_name_one, :string
    add_column :breweries, :string, :string
    add_column :breweries, :alt_name_two, :string
    add_column :breweries, :alt_name_three, :string
  end
end
