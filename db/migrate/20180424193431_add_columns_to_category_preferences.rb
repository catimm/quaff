class AddColumnsToCategoryPreferences < ActiveRecord::Migration[5.1]
  def change
    add_column :user_preference_beers, :journey_stage, :integer
    add_column :user_preference_ciders, :journey_stage, :integer
    add_column :user_preference_wines, :journey_stage, :integer
  end
end
