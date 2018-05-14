class AddSubscriptionLevelGroupToFedExDeliveryZone < ActiveRecord::Migration[5.1]
  def change
    add_column :fed_ex_delivery_zones, :subscription_level_group, :integer
  end
end
