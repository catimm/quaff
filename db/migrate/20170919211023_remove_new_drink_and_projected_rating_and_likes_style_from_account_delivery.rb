class RemoveNewDrinkAndProjectedRatingAndLikesStyleFromAccountDelivery < ActiveRecord::Migration
  def change
    remove_column :account_deliveries, :new_drink, :boolean
    remove_column :account_deliveries, :projected_rating, :float
    remove_column :account_deliveries, :likes_style, :string
  end
end
