class DropDrinkList < ActiveRecord::Migration
  def change
    drop_table :drink_lists
  end
end
