class RemoveProjectedRatingFromModels < ActiveRecord::Migration
  def change
    remove_column :user_cellar_supplies, :projected_rating, :float
    remove_column :admin_account_deliveries, :projected_rating, :float
    remove_column :user_deliveries, :projected_rating, :float
    remove_column :wishlists, :projected_rating, :float
  end
end
