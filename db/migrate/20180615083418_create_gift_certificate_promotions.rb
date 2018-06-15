class CreateGiftCertificatePromotions < ActiveRecord::Migration[5.1]
  def change
    create_table :gift_certificate_promotions do |t|
      t.references :gift_certificate, foreign_key: true
      t.integer :promotion_gift_certificate_id

      t.timestamps
    end
  end
end
