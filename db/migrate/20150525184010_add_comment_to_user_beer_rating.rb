class AddCommentToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :comment, :text
  end
end
