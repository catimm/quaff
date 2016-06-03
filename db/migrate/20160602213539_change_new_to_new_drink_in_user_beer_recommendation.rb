class ChangeNewToNewDrinkInUserBeerRecommendation < ActiveRecord::Migration
  def change
    rename_column :user_drink_recommendations, :new, :new_drink
  end
end
