class AddNewDrinkAndLikesStyleToAdminUserDeliveries < ActiveRecord::Migration
  def change
    add_column :admin_user_deliveries, :new_drink, :boolean
    add_column :admin_user_deliveries, :likes_style, :string
  end
end
