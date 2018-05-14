class AddBeerPriceResponseAndBeerPriceLimitToUserPreferenceBeer < ActiveRecord::Migration[5.1]
  def change
    add_column :user_preference_beers, :beer_price_response, :string
    add_column :user_preference_beers, :beer_price_limit, :decimal, :precision => 5, :scale => 2
  end
end
