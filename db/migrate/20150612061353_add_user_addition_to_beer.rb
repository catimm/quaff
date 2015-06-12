class AddUserAdditionToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :user_addition, :boolean
  end
end
