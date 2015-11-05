class AddSpecialDesignationAndSpecialDesignationColorToBeerLocation < ActiveRecord::Migration
  def change
    add_column :beer_locations, :special_designation, :boolean
    add_column :beer_locations, :special_designation_color, :string
  end
end
