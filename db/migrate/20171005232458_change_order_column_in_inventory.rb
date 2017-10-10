class ChangeOrderColumnInInventory < ActiveRecord::Migration
  def change
    rename_column :inventories, :order_queue, :order_request
  end
end
