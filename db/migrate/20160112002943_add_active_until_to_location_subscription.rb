class AddActiveUntilToLocationSubscription < ActiveRecord::Migration
  def change
    add_column :location_subscriptions, :active_until, :datetime
  end
end
