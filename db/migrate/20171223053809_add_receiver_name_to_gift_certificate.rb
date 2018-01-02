class AddReceiverNameToGiftCertificate < ActiveRecord::Migration
  def change
    add_column :gift_certificates, :receiver_name, :string
  end
end
