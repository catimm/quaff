class AddCustomerHasPreviousPackagingToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :customer_has_previous_packaging, :boolean
  end
end
