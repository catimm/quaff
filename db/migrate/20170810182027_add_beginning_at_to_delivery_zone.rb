class AddBeginningAtToDeliveryZone < ActiveRecord::Migration
  def change
    add_column :delivery_zones, :beginning_at, :datetime
  end
end
