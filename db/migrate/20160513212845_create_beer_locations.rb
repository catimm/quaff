class CreateBeerLocations < ActiveRecord::Migration
  def change
    create_table :beer_locations do |t|
      t.integer :beer_id
      t.integer :location_id
      t.datetime :removed_at
      t.integer :tap_number
      t.integer :draft_board_id

      t.timestamps null: false
    end
  end
end
