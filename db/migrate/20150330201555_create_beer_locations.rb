class CreateBeerLocations < ActiveRecord::Migration
  def change
    create_table :beer_locations do |t|
      t.integer :beer_id
      t.integer :location_id
      t.string :current

      t.timestamps
    end
  end
end
