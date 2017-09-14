class RemoveAdminVettedFromWishlist < ActiveRecord::Migration
  def change
    remove_column :wishlists, :admin_vetted, :boolean
  end
end
