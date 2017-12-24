class CreateGiftCertificates < ActiveRecord::Migration
  def change
    create_table :gift_certificates do |t|
      t.string :giver_name
      t.string :giver_email
      t.string :receiver_email
      t.decimal :amount
      t.string :redeem_code

      t.timestamps null: false
    end
  end
end
