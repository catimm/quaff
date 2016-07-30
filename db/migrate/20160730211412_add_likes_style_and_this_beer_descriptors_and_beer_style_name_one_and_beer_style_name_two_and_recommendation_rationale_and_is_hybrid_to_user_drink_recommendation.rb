class AddLikesStyleAndThisBeerDescriptorsAndBeerStyleNameOneAndBeerStyleNameTwoAndRecommendationRationaleAndIsHybridToUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :likes_style, :boolean
    add_column :user_drink_recommendations, :this_beer_descriptors, :text
    add_column :user_drink_recommendations, :beer_style_name_one, :string
    add_column :user_drink_recommendations, :beer_style_name_two, :string
    add_column :user_drink_recommendations, :recommendation_rationale, :string
    add_column :user_drink_recommendations, :is_hybrid, :boolean
  end
end
