class AddHasCustomerAdditionsToDelivery < ActiveRecord::Migration[5.1]
  def change
    add_column :deliveries, :has_customer_additions, :boolean
  end
end
