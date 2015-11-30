class AddLocationIdToAuthentication < ActiveRecord::Migration
  def change
    add_column :authentications, :location_id, :integer
  end
end
