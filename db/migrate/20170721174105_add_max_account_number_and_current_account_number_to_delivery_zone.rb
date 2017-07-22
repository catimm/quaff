class AddMaxAccountNumberAndCurrentAccountNumberToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :max_account_number, :integer
    add_column :delivery_zones, :current_account_number, :integer
  end
end
