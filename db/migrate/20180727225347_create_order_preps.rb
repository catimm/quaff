class CreateOrderPreps < ActiveRecord::Migration[5.1]
  def change
    create_table :order_preps do |t|
      t.integer :account_id
      t.datetime :delivery_date
      t.decimal :subtotal, :precision => 6, :scale => 2
      t.decimal :sales_tax, :precision => 6, :scale => 2
      t.decimal :total_drink_price, :precision => 6, :scale => 2
      t.string :status
      t.text  :admin_delivery_review_note
      t.text  :admin_delivery_confirmation_note
      t.boolean :delivery_change_confirmation
      t.boolean :share_admin_prep_with_user
      t.integer :curation_request_id
      t.decimal :delivery_fee, :precision => 6, :scale => 2
      t.decimal :grand_total, :precision => 6, :scale => 2
      
      t.timestamps
    end
  end
end
