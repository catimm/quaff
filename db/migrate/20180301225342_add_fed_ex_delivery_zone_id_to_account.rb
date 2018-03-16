class AddFedExDeliveryZoneIdToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :fed_ex_delivery_zone_id, :integer
  end
end
