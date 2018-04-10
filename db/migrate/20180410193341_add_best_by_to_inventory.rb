class AddBestByToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :best_by, :date
  end
end
