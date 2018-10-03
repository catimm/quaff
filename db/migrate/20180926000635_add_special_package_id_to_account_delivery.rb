class AddSpecialPackageIdToAccountDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :account_deliveries, :special_package_id, :integer
  end
end
