class AddSizeFormatIdToUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :size_format_id, :integer
  end
end
