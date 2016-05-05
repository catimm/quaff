class AddDrinkRankToUserFavDrink < ActiveRecord::Migration
  def change
    add_column :user_fav_drinks, :drink_rank, :integer
  end
end
