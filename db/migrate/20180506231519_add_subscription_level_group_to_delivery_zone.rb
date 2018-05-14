class AddSubscriptionLevelGroupToDeliveryZone < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_zones, :subscription_level_group, :integer
  end
end
