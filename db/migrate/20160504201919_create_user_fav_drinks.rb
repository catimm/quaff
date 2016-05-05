class CreateUserFavDrinks < ActiveRecord::Migration
  def change
    create_table :user_fav_drinks do |t|
      t.integer :user_id
      t.integer :beer_id

      t.timestamps null: false
    end
  end
end
