class ChangeUserDrinkRecommendationColumns < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :account_id, :integer
    remove_column :user_drink_recommendations, :likes_style, :string
    remove_column :user_drink_recommendations, :this_beer_descriptors, :text
    remove_column :user_drink_recommendations, :beer_style_name_one, :string
    remove_column :user_drink_recommendations, :beer_style_name_two, :string
    remove_column :user_drink_recommendations, :recommendation_rationale, :string
    remove_column :user_drink_recommendations, :is_hybrid, :boolean
  end
end
