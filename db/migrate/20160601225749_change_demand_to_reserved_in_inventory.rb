class ChangeDemandToReservedInInventory < ActiveRecord::Migration
  def change
    rename_column :inventories, :demand, :reserved
  end
end
