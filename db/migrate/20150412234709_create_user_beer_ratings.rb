class CreateUserBeerRatings < ActiveRecord::Migration
  def change
    create_table :user_beer_ratings do |t|
      t.integer :user_id
      t.integer :beer_id
      t.decimal :user_beer_rating
      t.string :beer_descriptors

      t.timestamps
    end
  end
end
