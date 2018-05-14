class ChangeColumnsInCategoryPreferences < ActiveRecord::Migration[5.1]
  def change
    change_column :user_preference_beers, :beers_per_week, :decimal, :precision => 4, :scale => 2
    change_column :user_preference_ciders, :ciders_per_week, :decimal, :precision => 4, :scale => 2
    change_column :user_preference_wines, :glasses_per_week, :decimal, :precision => 4, :scale => 2
  end
end
