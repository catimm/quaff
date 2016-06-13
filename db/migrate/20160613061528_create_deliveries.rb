class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.integer :user_id
      t.datetime :delivery_date
      t.decimal :subtotal, :precision => 6, :scale => 2
      t.decimal :sales_tax, :precision => 6, :scale => 2
      t.decimal :total_price, :precision => 6, :scale => 2
      t.string :status

      t.timestamps null: false
    end
  end
end
