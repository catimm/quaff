class AddDeliveryZoneIdToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :delivery_zone_id, :integer
  end
end
