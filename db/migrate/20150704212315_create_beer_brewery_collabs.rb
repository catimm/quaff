class CreateBeerBreweryCollabs < ActiveRecord::Migration
  def change
    create_table :beer_brewery_collabs do |t|
      t.integer :beer_id
      t.integer :brewery_id

      t.timestamps null: false
    end
  end
end
