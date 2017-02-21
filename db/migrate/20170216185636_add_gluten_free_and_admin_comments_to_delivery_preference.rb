class AddGlutenFreeAndAdminCommentsToDeliveryPreference < ActiveRecord::Migration
  def change
    add_column :delivery_preferences, :gluten_free, :boolean
    add_column :delivery_preferences, :admin_comments, :text
  end
end
