class AddTapNumberToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :tap_number, :integer
  end
end
