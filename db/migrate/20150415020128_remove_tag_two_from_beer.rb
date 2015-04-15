class RemoveTagTwoFromBeer < ActiveRecord::Migration
  def change
    remove_column :beers, :tag_two, :string
  end
end
