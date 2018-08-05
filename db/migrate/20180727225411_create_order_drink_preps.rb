class CreateOrderDrinkPreps < ActiveRecord::Migration[5.1]
  def change
    create_table :order_drink_preps do |t|
      t.integer :user_id
      t.integer :account_id
      t.integer :inventory_id
      t.integer :order_prep_id
      t.integer :quantity
      t.decimal :drink_price, :precision => 6, :scale => 2
      t.timestamps
    end
  end
end
