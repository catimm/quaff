class AddNewToUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :new, :boolean
  end
end
