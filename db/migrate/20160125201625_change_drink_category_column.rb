class ChangeDrinkCategoryColumn < ActiveRecord::Migration
  def change
    rename_column :drink_categories, :category_position_integer, :category_position
    change_column :drink_categories, :category_position, 'integer USING CAST(category_position AS integer)'
  end
end
