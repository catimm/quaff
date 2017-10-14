class ChangeColumnNameDistiInventory < ActiveRecord::Migration
  def change
    rename_column :disti_inventories, :sale_case_cost, :current_case_cost
  end
end
