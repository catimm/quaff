class RemoveForeignKeyOnDelivery < ActiveRecord::Migration[5.1]
  def change
    # remove the old foreign_key
    remove_foreign_key :deliveries, :curation_requests
  end
end
