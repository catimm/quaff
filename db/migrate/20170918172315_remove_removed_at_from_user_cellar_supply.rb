class RemoveRemovedAtFromUserCellarSupply < ActiveRecord::Migration
  def change
    remove_column :user_cellar_supplies, :removed_at, :datetime
    add_column :user_cellar_supplies, :remaining_quantity, :integer
    rename_column :user_cellar_supplies, :quantity, :total_quantity
  end
end
