class AddUserRatedToProjectedRating < ActiveRecord::Migration[5.1]
  def change
    add_column :projected_ratings, :user_rated, :boolean
  end
end
