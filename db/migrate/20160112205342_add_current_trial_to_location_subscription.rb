class AddCurrentTrialToLocationSubscription < ActiveRecord::Migration
  def change
    add_column :location_subscriptions, :current_trial, :boolean
  end
end
