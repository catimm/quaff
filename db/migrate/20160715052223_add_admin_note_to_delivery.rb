class AddAdminNoteToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :admin_note, :text
  end
end
