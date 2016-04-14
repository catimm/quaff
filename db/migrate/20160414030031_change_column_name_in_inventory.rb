class ChangeColumnNameInInventory < ActiveRecord::Migration
  def change
    rename_column :inventories, :format_id, :size_format_id
  end
end
