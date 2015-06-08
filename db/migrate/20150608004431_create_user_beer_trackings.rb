class CreateUserBeerTrackings < ActiveRecord::Migration
  def change
    create_table :user_beer_trackings do |t|
      t.integer :user_id
      t.integer :beer_id
      t.integer :location_id
      t.datetime :removed_at

      t.timestamps null: false
    end
  end
end
