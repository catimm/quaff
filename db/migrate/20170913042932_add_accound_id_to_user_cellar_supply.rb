class AddAccoundIdToUserCellarSupply < ActiveRecord::Migration
  def change
    add_column :user_cellar_supplies, :account_id, :integer
  end
end
