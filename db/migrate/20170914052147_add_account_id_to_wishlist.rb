class AddAccountIdToWishlist < ActiveRecord::Migration
  def change
    add_column :wishlists, :account_id, :integer
  end
end
