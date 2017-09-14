class AddTotalBatchAndCurrentlyAvailableToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :total_batch, :integer
    add_column :inventories, :currently_available, :boolean
  end
end
