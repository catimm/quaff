class AddTotalDemandToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :total_demand, :integer
  end
end
