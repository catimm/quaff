class AddLikesStyleAndThisBeerDescriptorsAndBeerStyleNameOneAndBeerStyleNameTwoAndRecommendationRationaleAndIsHybridToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :likes_style, :boolean
    add_column :user_supplies, :this_beer_descriptors, :text
    add_column :user_supplies, :beer_style_name_one, :string
    add_column :user_supplies, :beer_style_name_two, :string
    add_column :user_supplies, :recommendation_rationale, :string
    add_column :user_supplies, :is_hybrid, :boolean
  end
end
