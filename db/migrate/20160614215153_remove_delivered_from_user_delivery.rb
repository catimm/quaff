class RemoveDeliveredFromUserDelivery < ActiveRecord::Migration
  def change
    remove_column :user_deliveries, :delivered, :datetime
  end
end
