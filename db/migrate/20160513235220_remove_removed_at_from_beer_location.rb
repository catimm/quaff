class RemoveRemovedAtFromBeerLocation < ActiveRecord::Migration
  def change
    remove_column :beer_locations, :removed_at, :datetime
  end
end
