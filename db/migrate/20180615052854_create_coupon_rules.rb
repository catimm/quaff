class CreateCouponRules < ActiveRecord::Migration[5.1]
  def change
    create_table :coupon_rules do |t|
      t.references :coupon, foreign_key: true
      t.decimal :original_value_start
      t.decimal :original_value_end
      t.float :add_value_percent
      t.decimal :add_value_amount
      t.text :description

      t.timestamps
    end
  end
end
