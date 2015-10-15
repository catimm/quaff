class AddKegSizeToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :keg_size, :integer
  end
end
