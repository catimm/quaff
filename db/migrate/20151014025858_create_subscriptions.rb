class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :subscription_level

      t.timestamps null: false
    end
  end
end
