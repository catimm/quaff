class RemoveLocationIdFromUserBeerTracking < ActiveRecord::Migration
  def change
    remove_column :user_beer_trackings, :location_id, :integer
  end
end
