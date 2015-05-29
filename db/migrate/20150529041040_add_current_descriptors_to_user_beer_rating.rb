class AddCurrentDescriptorsToUserBeerRating < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :current_descriptors, :text
  end
end
