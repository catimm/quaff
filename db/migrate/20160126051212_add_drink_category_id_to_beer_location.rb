class AddDrinkCategoryIdToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :drink_category_id, :integer
  end
end
