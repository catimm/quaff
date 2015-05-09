class AddBeerStyleIdToBeerType < ActiveRecord::Migration
  def change
    add_column :beer_types, :beer_style_id, :integer
  end
end
