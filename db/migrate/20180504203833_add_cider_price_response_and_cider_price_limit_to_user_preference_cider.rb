class AddCiderPriceResponseAndCiderPriceLimitToUserPreferenceCider < ActiveRecord::Migration[5.1]
  def change
    add_column :user_preference_ciders, :cider_price_response, :string
    add_column :user_preference_ciders, :cider_price_limit, :decimal, :precision => 5, :scale => 2
  end
end
