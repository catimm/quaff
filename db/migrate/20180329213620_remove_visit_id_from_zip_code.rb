class RemoveVisitIdFromZipCode < ActiveRecord::Migration
  def change
    remove_column :zip_codes, :visit_id, :uuid
  end
end
