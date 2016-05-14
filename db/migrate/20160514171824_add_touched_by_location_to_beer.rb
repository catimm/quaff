class AddTouchedByLocationToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :touched_by_location, :integer
  end
end
