class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :account, index: true
      t.string :drink_type
      t.integer :number_of_drinks
      t.integer :number_of_large_drinks
      t.datetime :delivery_date
      t.string :additional_requests

      t.timestamps null: false
    end
    add_foreign_key :orders, :accounts
  end
end
