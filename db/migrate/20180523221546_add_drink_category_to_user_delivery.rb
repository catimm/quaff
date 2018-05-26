class AddDrinkCategoryToUserDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :user_deliveries, :drink_category, :string
  end
end
