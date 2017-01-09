class AddColumnsToUserTables < ActiveRecord::Migration
  def change
    add_column :user_beer_ratings, :admin_vetted, :boolean
    add_column :wishlists, :admin_vetted, :boolean
    add_column :user_supplies, :admin_vetted, :boolean
  end
end
