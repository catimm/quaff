class AddAccountDeliveryIdToUserCellarSupply < ActiveRecord::Migration
  def change
    add_column :user_cellar_supplies, :account_delivery_id, :integer
  end
end
