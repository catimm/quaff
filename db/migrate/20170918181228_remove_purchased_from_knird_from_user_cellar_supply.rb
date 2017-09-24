class RemovePurchasedFromKnirdFromUserCellarSupply < ActiveRecord::Migration
  def change
    remove_column :user_cellar_supplies, :purchased_from_knird, :boolean
  end
end
