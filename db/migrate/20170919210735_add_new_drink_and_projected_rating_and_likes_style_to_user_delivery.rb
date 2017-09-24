class AddNewDrinkAndProjectedRatingAndLikesStyleToUserDelivery < ActiveRecord::Migration
  def change
    add_column :user_deliveries, :new_drink, :boolean
    add_column :user_deliveries, :projected_rating, :float
    add_column :user_deliveries, :likes_style, :string
  end
end
