class AddPremiumDrinkToDraftDetail < ActiveRecord::Migration
  def change
    add_column :draft_details, :premium_drink, :boolean
  end
end
