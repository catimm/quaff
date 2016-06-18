class AddQuantityToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :quantity, :integer
  end
end
