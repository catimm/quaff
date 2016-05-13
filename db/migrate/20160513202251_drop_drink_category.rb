class DropDrinkCategory < ActiveRecord::Migration
  def change
    drop_table :drink_categories
  end
end
