class AddReserveForCustomerToUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :reserve_for_customer, :boolean
  end
end
