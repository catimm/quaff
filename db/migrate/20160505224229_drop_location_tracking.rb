class DropLocationTracking < ActiveRecord::Migration
  def change
    drop_table :location_trackings
  end
end
