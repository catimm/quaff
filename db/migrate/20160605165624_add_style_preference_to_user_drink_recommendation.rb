class AddStylePreferenceToUserDrinkRecommendation < ActiveRecord::Migration
  def change
    add_column :user_drink_recommendations, :style_preference, :string
  end
end
