class AddRecipientIs21PlusToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :recipient_is_21_plus, :boolean
  end
end
