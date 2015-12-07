class AddOwnerToUserLocation < ActiveRecord::Migration
  def change
    add_column :user_locations, :owner, :boolean
  end
end
