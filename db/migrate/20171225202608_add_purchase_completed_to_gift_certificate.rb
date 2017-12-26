class AddPurchaseCompletedToGiftCertificate < ActiveRecord::Migration
  def change
    add_column :gift_certificates, :purchase_completed, :boolean
  end
end
