class AddMateToFriend < ActiveRecord::Migration
  def change
    add_column :friends, :mate, :boolean
  end
end
