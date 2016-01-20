class AddTrialEndedToLocationSubscription < ActiveRecord::Migration
  def change
    add_column :location_subscriptions, :trial_ended, :boolean
  end
end
