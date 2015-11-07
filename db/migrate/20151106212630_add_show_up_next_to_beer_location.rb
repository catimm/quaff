class AddShowUpNextToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :show_up_next, :boolean
  end
end
