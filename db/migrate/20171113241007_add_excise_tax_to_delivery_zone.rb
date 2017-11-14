class AddExciseTaxToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :excise_tax, :decimal, :precision => 8, :scale => 6
  end
end
