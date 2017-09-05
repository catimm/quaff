class AddPurchasedFromKnirdToUserSupply < ActiveRecord::Migration
  def change
    add_column :user_supplies, :purchased_from_knird, :boolean
  end
end
