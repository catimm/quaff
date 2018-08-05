class AddDrinkCategoryAndShowCurrentInventoryToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :drink_category, :string
    add_column :inventories, :show_current_inventory, :boolean
  end
end
