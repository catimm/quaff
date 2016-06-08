class RemoveReserveForCustomerFromUserDrinkRecommendation < ActiveRecord::Migration
  def change
    remove_column :user_drink_recommendations, :reserve_for_customer, :boolean
  end
end
