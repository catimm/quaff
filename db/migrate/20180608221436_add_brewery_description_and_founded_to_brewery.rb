class AddBreweryDescriptionAndFoundedToBrewery < ActiveRecord::Migration[5.1]
  def change
    add_column :breweries, :brewery_description, :text
    add_column :breweries, :founded, :string
  end
end
