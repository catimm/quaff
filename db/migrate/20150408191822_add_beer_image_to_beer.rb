class AddBeerImageToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :beer_image, :string
  end
end
