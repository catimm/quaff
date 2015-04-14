class CreateDrinkLists < ActiveRecord::Migration
  def change
    create_table :drink_lists do |t|
      t.integer :user_id
      t.integer :beer_id

      t.timestamps
    end
  end
end
