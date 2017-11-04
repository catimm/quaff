class ChangeColumnNameInDistiOrder < ActiveRecord::Migration
  def change
    rename_column :disti_orders, :disti_inventory_id, :distributor_id
  end
end
