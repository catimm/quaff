class CreateFreeCurations < ActiveRecord::Migration[5.1]
  def change
    create_table :free_curations do |t|
      t.integer :account_id
      t.date :requested_date
      t.decimal :subtotal, precision: 6, scale: 2
      t.decimal :sales_tax, precision: 6, scale: 2
      t.decimal :total_price, precision: 6, scale: 2
      t.string :status
      t.text :admin_curation_note
      t.boolean :share_admin_prep

      t.timestamps
    end
  end
end
