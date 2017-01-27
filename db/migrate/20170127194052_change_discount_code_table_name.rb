class ChangeDiscountCodeTableName < ActiveRecord::Migration
  def change
    rename_table :discount_codes, :special_codes
  end
end
