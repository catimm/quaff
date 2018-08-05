class AddKnirdPreferredOnlyToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :membership_only, :boolean
  end
end
