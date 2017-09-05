class RenameUserSupplyToUserCellarSupply < ActiveRecord::Migration
  def change
    rename_table :user_supplies, :user_cellar_supplies
  end
end
