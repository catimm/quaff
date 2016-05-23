class CreateUserSubscriptions < ActiveRecord::Migration
  def change
    create_table :user_subscriptions do |t|
      t.integer :user_id
      t.integer :subscription_id
      t.datetime :active_until
      t.string :stripe_customer_number
      t.string :stripe_subscription_number
      t.boolean :current_trial
      t.boolean :trial_ended

      t.timestamps null: false
    end
  end
end
