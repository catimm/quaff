class ChangeOldAdminModelsToFreeCuration < ActiveRecord::Migration[5.1]
  def change
    rename_table :admin_account_deliveries, :free_curation_accounts
    rename_table :admin_user_deliveries, :free_curation_users
    rename_column :free_curation_accounts, :delivery_id, :free_curation_id
    rename_column :free_curation_users, :delivery_id, :free_curation_id
    rename_column :free_curation_users, :admin_account_delivery_id, :free_curation_account_id
    add_column :free_curation_accounts, :size_format_id, :integer
  end
end
