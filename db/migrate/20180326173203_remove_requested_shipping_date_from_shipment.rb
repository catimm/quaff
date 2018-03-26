class RemoveRequestedShippingDateFromShipment < ActiveRecord::Migration
  def change
    remove_column :shipments, :requested_shipping_date, :date
  end
end
