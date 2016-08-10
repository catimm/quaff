class AddShareAdminPrepWithUserToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :share_admin_prep_with_user, :boolean
  end
end
