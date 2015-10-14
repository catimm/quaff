class CreateUserSubscriptions < ActiveRecord::Migration
  def change
    create_table :user_subscriptions do |t|
      t.integer :user_id
      t.integer :subscription_id

      t.timestamps null: false
    end
  end
end
