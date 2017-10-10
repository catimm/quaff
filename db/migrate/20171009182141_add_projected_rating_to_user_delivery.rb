class AddProjectedRatingToUserDelivery < ActiveRecord::Migration
  def change
    add_column :user_deliveries, :projected_rating, :float
  end
end
