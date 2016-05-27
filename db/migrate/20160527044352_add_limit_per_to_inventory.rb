class AddLimitPerToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :limit_per, :integer
  end
end
