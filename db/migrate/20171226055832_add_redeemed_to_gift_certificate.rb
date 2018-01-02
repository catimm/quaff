class AddRedeemedToGiftCertificate < ActiveRecord::Migration
  def change
    add_column :gift_certificates, :redeemed, :boolean
  end
end
