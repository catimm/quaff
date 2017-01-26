class ChangeDiscountCodeToCodeInUser < ActiveRecord::Migration
  def change
    rename_column :users, :discount_code, :special_code
  end
end
