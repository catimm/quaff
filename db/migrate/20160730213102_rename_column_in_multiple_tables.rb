class RenameColumnInMultipleTables < ActiveRecord::Migration
  def change
    rename_column :user_deliveries, :style_preference, :likes_style
    rename_column :admin_user_deliveries, :style_preference, :likes_style
    rename_column :user_drink_recommendations, :style_preference, :likes_style
  end
end
