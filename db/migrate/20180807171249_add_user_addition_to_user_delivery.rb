class AddUserAdditionToUserDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :user_deliveries, :user_addition, :boolean
  end
end
