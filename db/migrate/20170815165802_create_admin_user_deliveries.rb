class CreateAdminUserDeliveries < ActiveRecord::Migration
  def change
    create_table :admin_user_deliveries do |t|
      t.integer :user_id
      t.integer :account_delivery_id
      t.integer :delivery_id
      t.float :quantity

      t.timestamps null: false
    end
  end
end
