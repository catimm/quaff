class AddBeerTypeShortNameToBeerType < ActiveRecord::Migration
  def change
    add_column :beer_types, :beer_type_short_name, :string
  end
end
