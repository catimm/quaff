class ChangeAdminNotesInDelivery < ActiveRecord::Migration
  def change
    rename_column :deliveries, :admin_note, :admin_delivery_review_note
    add_column :deliveries, :admin_delivery_confirmation_note, :text
  end
end
