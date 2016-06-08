class DropUserDelivery < ActiveRecord::Migration
  def change
    drop_table :user_deliveries
  end
end
