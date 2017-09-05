class ChangeMoreColumnsInUserDelivery < ActiveRecord::Migration
  def change
    rename_column :user_deliveries, :user_id, :account_id
    add_column :user_deliveries, :times_rated, :integer
    add_column :user_deliveries, :moved_to_cellar_supply, :boolean
  end
end
