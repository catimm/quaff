class RemoveAdminApprovedFromBeer < ActiveRecord::Migration
  def change
    remove_column :beers, :admin_approved, :boolean
  end
end
