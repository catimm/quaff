class RemoveLikesStyleFromMultipleTables < ActiveRecord::Migration
  def change
    remove_column :user_supplies, :likes_style, :boolean
    remove_column :user_deliveries, :likes_style, :boolean
    remove_column :admin_user_deliveries, :likes_style, :boolean
    remove_column :user_drink_recommendations, :likes_style, :boolean
  end
end
