class AddVisitIdToZipCode < ActiveRecord::Migration
  def change
    add_column :zip_codes, :visit_id, :bigint
  end
end
