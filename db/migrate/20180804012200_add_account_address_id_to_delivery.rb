class AddAccountAddressIdToDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :deliveries, :account_address_id, :integer
  end
end
