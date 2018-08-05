class RemoveShareAdminPrepWithUserAndAdminDeliveryReviewNoteAndAdminDeliveryConfirmationNoteAndDeliveryChangeConfirmationFromOrderPrep < ActiveRecord::Migration[5.1]
  def change
    remove_column :order_preps, :share_admin_prep_with_user, :boolean
    remove_column :order_preps, :admin_delivery_review_note, :text
    remove_column :order_preps, :admin_delivery_confirmation_note, :text
    remove_column :order_preps, :delivery_change_confirmation, :boolean
  end
end
