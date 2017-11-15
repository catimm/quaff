class AddColumnsToUserDrinkRecommendations < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :number_of_ratings, :integer
    add_column :user_drink_recommendations, :delivered_recently, :boolean
    add_column :user_drink_recommendations, :drank_recently, :boolean
  end
end
