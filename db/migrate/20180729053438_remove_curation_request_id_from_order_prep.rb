class RemoveCurationRequestIdFromOrderPrep < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_preps, :curation_request_id, :integer
  end
end
