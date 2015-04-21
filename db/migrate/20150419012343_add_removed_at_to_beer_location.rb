class AddRemovedAtToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :removed_at, :datetime
  end
end
