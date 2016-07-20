class AddChangeNotedToCustomerDeliveryChange < ActiveRecord::Migration
  def change
    add_column :customer_delivery_changes, :change_noted, :boolean
  end
end
