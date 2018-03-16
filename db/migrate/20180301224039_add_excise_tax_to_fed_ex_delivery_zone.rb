class AddExciseTaxToFedExDeliveryZone < ActiveRecord::Migration
  def change
    add_column :fed_ex_delivery_zones, :excise_tax, :decimal, :precision => 8, :scale => 6
  end
end
