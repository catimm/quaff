class AddRemovedAtToUserCellarSupply < ActiveRecord::Migration
  def change
    add_column :user_cellar_supplies, :removed_at, :datetime
  end
end
