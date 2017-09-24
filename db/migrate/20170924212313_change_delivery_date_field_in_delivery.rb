class ChangeDeliveryDateFieldInDelivery < ActiveRecord::Migration
  def change
    change_column :deliveries, :delivery_date, :date
  end
end
