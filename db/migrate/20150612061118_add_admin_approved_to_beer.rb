class AddAdminApprovedToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :admin_approved, :boolean
  end
end
