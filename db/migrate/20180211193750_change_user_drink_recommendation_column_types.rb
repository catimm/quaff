class ChangeUserDrinkRecommendationColumnTypes < ActiveRecord::Migration
  def change
    remove_column :user_drink_recommendations, :delivered_recently, :boolean
    remove_column :user_drink_recommendations, :drank_recently, :boolean
    add_column :user_drink_recommendations, :delivered_recently, :date
    add_column :user_drink_recommendations, :drank_recently, :date
  end
end
