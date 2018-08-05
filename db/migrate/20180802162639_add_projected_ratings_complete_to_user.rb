class AddProjectedRatingsCompleteToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :projected_ratings_complete, :boolean
  end
end
