class AddNextDeliveryDateToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :next_delivery_date, :datetime
  end
end
