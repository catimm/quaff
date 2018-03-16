class ChangeColumnTypesInFedExDeliveryZone < ActiveRecord::Migration
  def change
    remove_column :fed_ex_delivery_zones, :zip_start, :integer
    remove_column :fed_ex_delivery_zones, :zip_end, :integer
    add_column :fed_ex_delivery_zones, :zip_start, :string
    add_column :fed_ex_delivery_zones, :zip_end, :string
  end
end
