class CreateLocationTrackings < ActiveRecord::Migration
  def change
    create_table :location_trackings do |t|
      t.integer :user_beer_tracking_id
      t.integer :location_id

      t.timestamps null: false
    end
  end
end
