class AddAltOneBeerTypeNameAndAltTwoBeerTypeNameToBeerType < ActiveRecord::Migration
  def change
    add_column :beer_types, :alt_one_beer_type_name, :string
    add_column :beer_types, :alt_two_beer_type_name, :string
  end
end
