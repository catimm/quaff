class ChangeColumnNameInBeer < ActiveRecord::Migration
  def change
    rename_column :beers, :beer_rating, :beer_rating_one
    rename_column :beers, :number_ratings, :number_ratings_one
    add_column :beers, :beer_rating_two, :float
    add_column :beers, :number_ratings_two, :integer
    add_column :beers, :beer_rating_three, :float
    add_column :beers, :number_ratings_three, :integer
  end
end
