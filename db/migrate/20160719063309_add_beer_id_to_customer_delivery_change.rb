class AddBeerIdToCustomerDeliveryChange < ActiveRecord::Migration
  def change
    add_column :customer_delivery_changes, :beer_id, :integer
  end
end
