class AddNonmemberLimitToInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :inventories, :nonmember_limit, :integer
  end
end
