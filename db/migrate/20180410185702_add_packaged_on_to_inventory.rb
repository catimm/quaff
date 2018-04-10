class AddPackagedOnToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :packaged_on, :date
  end
end
