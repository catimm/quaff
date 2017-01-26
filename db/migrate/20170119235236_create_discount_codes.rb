class CreateDiscountCodes < ActiveRecord::Migration
  def change
    create_table :discount_codes do |t|
      t.string :discount_code
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
