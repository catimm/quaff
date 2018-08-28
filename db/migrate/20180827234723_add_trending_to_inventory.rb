class AddTrendingToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :trending, :boolean
  end
end
