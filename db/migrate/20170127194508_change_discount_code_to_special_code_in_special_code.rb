class ChangeDiscountCodeToSpecialCodeInSpecialCode < ActiveRecord::Migration
  def change
    rename_column :special_codes, :discount_code, :special_code
  end
end
