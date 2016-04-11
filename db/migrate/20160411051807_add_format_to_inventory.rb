class AddFormatToInventory < ActiveRecord::Migration
  def change
    add_column :inventories, :format_id, :integer
  end
end
