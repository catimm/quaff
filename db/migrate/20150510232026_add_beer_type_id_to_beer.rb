class AddBeerTypeIdToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :beer_type_id, :integer
  end
end
