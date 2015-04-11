class AddTagOneAndTagTwoToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :tag_one, :string
    add_column :beers, :tag_two, :string
  end
end
