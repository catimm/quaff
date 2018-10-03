class AddSpecialPackageIdToOrderDrinkPrep < ActiveRecord::Migration[5.1]
  def change
    add_column :order_drink_preps, :special_package_id, :integer
  end
end
