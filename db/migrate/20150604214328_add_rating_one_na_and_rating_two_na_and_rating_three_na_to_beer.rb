class AddRatingOneNaAndRatingTwoNaAndRatingThreeNaToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :rating_one_na, :boolean
    add_column :beers, :rating_two_na, :boolean
    add_column :beers, :rating_three_na, :boolean
  end
end
