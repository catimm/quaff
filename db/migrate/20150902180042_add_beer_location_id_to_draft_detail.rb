class AddBeerLocationIdToDraftDetail < ActiveRecord::Migration
  def change
    add_column :draft_details, :beer_location_id, :integer
  end
end
