class AddWentLiveToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :went_live, :datetime
  end
end
