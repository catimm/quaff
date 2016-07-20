class AddDeliveryChangeConfirmationToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :delivery_change_confirmation, :boolean
  end
end
