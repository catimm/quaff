class AddVisitIdToGiftCertificate < ActiveRecord::Migration[5.1]
  def change
    add_column :gift_certificates, :visit_id, :bigint
  end
end
