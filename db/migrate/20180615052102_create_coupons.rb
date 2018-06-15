class CreateCoupons < ActiveRecord::Migration[5.1]
  def change
    create_table :coupons do |t|
      t.string :code
      t.datetime :valid_from
      t.datetime :valid_till
      t.text :description

      t.timestamps
    end
  end
end
