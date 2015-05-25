class RemoveBeerDescriptorsFromUserBeerRating < ActiveRecord::Migration
  def change
    remove_column :user_beer_ratings, :beer_descriptors, :string
  end
end
