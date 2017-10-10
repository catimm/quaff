class AddProjectedRatingToAdminUserDelivery < ActiveRecord::Migration
  def change
    add_column :admin_user_deliveries, :projected_rating, :float
  end
end
