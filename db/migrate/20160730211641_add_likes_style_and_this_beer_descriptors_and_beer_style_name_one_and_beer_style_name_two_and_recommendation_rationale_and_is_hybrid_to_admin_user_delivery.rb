class AddLikesStyleAndThisBeerDescriptorsAndBeerStyleNameOneAndBeerStyleNameTwoAndRecommendationRationaleAndIsHybridToAdminUserDelivery < ActiveRecord::Migration
  def change
    add_column :admin_user_deliveries, :likes_style, :boolean
    add_column :admin_user_deliveries, :this_beer_descriptors, :text
    add_column :admin_user_deliveries, :beer_style_name_one, :string
    add_column :admin_user_deliveries, :beer_style_name_two, :string
    add_column :admin_user_deliveries, :recommendation_rationale, :string
    add_column :admin_user_deliveries, :is_hybrid, :boolean
  end
end
