class ChangeVisitIdColumnTypeOnZipCode < ActiveRecord::Migration
  def change
    remove_column :zip_codes, :visit_id, :bigint
    add_column :zip_codes, :visit_id, :uuid
  end
end
