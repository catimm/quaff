class AddFinalDeliveryNotesToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :final_delivery_notes, :text
  end
end
